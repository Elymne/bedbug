import 'dart:convert';
import 'dart:math';

import 'package:bedbug/core/domain/cursor_page.dart';
import 'package:bedbug/infra/resources/content/content/content.entity.dart';
import 'package:bedbug/infra/resources/content/content/content.entity.detailed.dart';
import 'package:bedbug/infra/resources/content/content/content.entity.summary.dart';
import 'package:bedbug/infra/resources/content/content/content.extension.dart';
import 'package:bedbug/infra/resources/content/content/content.mapper.drift.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.dart';
import 'package:bedbug/infra/resources/content/content/content_origin.enum.dart';
import 'package:bedbug/infra/resources/content/content/content_score.entity.summary.dart';
import 'package:bedbug/infra/resources/content/content/content_type.enum.dart';
import 'package:bedbug/infra/resources/content/content/content_url.entity.summary.dart';
import 'package:bedbug/infra/resources/content/seen_content/seen_content.entity.dart';
import 'package:bedbug/infra/resources/content/seen_content/seen_content.mapper.drift.dart';
import 'package:bedbug/infra/resources/data.exception.dart';
import 'package:bedbug/infra/resources/drift.database.dart';
import 'package:bedbug/infra/resources/drift.guard.dart';
import 'package:bedbug/infra/resources/signature/signature/signature.mapper.drift.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nom du repository, repris dans ses exceptions.
const String _source = 'DriftContentRepository';

/// Nombre maximal d'identifiants passés dans une même clause `IN`, pour rester loin de la limite de variables de
/// SQLite quand une suppression vise des milliers de contenus.
const int _maxIdsPerStatement = 500;

/// Provider du [DriftContentRepository].
final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return DriftContentRepository(ref.read(appDatabaseProvider));
});

/// Implémentation de [ContentRepository] sur la base SQLite de l'app.
///
/// Les listes affichées (fil, recherche) sont lues en une requête par page : le contenu, la signature de son auteur
/// par jointure, son nombre de réactions et sa trace d'affichage par sous-requêtes. Elles sont paginées par curseur
/// (score d'affichage puis identifiant du dernier contenu de la page), jamais par décalage.
class DriftContentRepository implements ContentRepository {
  /// Crée un [DriftContentRepository].
  ///
  /// - [_database] : base de l'app.
  DriftContentRepository(this._database);

  /// Base de l'app.
  final AppDatabase _database;

  /// Nombre de réactions du contenu de la ligne lue, par sous-requête sur l'index des réactions.
  late final Expression<int> _reactionCount = subqueryExpression<int>(
    _database.selectOnly(_database.reactions)
      ..addColumns([_database.reactions.id.count()])
      ..where(_database.reactions.contentId.equalsExp(_database.contents.id)),
  );

  /// Indique si le contenu de la ligne lue a déjà été vu, quelle que soit la date.
  late final Expression<bool> _isViewedEver = _isViewedBefore(null);

  /// Nombre de réactions d'un contenu dans une lecture de résumés, groupée par contenu.
  late final Expression<int> _summaryReactionCount = _database.reactions.id.count();

  /// Date de la réaction la plus récente d'un contenu dans une lecture de résumés, en millisecondes.
  late final Expression<int> _summaryLatestReactionAt = _database.reactions.updatedAt.max();

  /// Voir [ContentRepository.addOne].
  @override
  Future<Content> addOne(Content entity) {
    return guardDrift(_source, () async {
      await _database
          .into(_database.contents)
          .insert(_insertCompanion(entity, DateTime.now()), onConflict: _upsert(entity));
      return entity;
    });
  }

  /// Seules les colonnes des formules de score sont lues : ni les textes, ni les médias, ni surtout le dessin, dont
  /// SQLite ne lit alors pas les pages de débordement.
  @override
  Future<List<ContentScoreSummary>> getReceivedScoreSummaries() {
    return guardDrift(_source, () async {
      final contents = _database.contents;
      final query = _database.selectOnly(contents)
        ..addColumns([
          contents.id,
          contents.origin,
          contents.createdAt,
          contents.bounce,
          contents.broadcastScore,
          contents.survivalScore,
          contents.displayScore,
        ])
        ..where(contents.origin.equals(ContentOrigin.owned.value).not());
      return [
        for (final row in await query.get())
          ContentScoreSummary(
            contentId: row.read(contents.id)!,
            origin: _originOf(row.read(contents.origin)!),
            createdAt: row.readWithConverter<DateTime, int>(contents.createdAt)!,
            bounce: row.read(contents.bounce)!,
            broadcastScore: row.read(contents.broadcastScore)!,
            survivalScore: row.read(contents.survivalScore)!,
            displayScore: row.read(contents.displayScore)!,
          ),
      ];
    });
  }

  /// Voir [ContentRepository.updateBroadcastScores].
  @override
  Future<void> updateBroadcastScores(Map<String, double> scoresById) {
    return _updateScores(scoresById, (score) => ContentsCompanion(broadcastScore: Value(score)));
  }

  /// Voir [ContentRepository.updateSurvivalScores].
  @override
  Future<void> updateSurvivalScores(Map<String, double> scoresById) {
    return _updateScores(scoresById, (score) => ContentsCompanion(survivalScore: Value(score)));
  }

  /// Voir [ContentRepository.updateDisplayScores].
  @override
  Future<void> updateDisplayScores(Map<String, double> scoresById) {
    return _updateScores(scoresById, (score) => ContentsCompanion(displayScore: Value(score)));
  }

  /// Seuls les liens et les médias qui ont au moins une adresse sont lus, et seulement leurs colonnes d'adresses : les
  /// textes et les dessins n'ont rien à confronter aux listes de domaines.
  @override
  Future<List<ContentUrlSummary>> getReceivedUrlSummaries() {
    return guardDrift(_source, () async {
      final contents = _database.contents;
      final isLink = contents.type.equals(ContentType.link.value);
      final isMediaWithUrls =
          contents.type.equals(ContentType.media.value) & contents.mediaUrls.equalsValue(const []).not();
      final query = _database.selectOnly(contents)
        ..addColumns([contents.id, contents.type, contents.url, contents.mediaUrls])
        ..where(contents.origin.equals(ContentOrigin.owned.value).not() & (isLink | isMediaWithUrls));
      final summaries = <ContentUrlSummary>[];
      for (final row in await query.get()) {
        final contentId = row.read(contents.id)!;
        if (row.read(contents.type) == ContentType.link.value) {
          final url = row.read(contents.url);
          if (url == null) {
            throw DataException(_source, 'lien "$contentId" sans adresse');
          }
          summaries.add(ContentUrlSummary(contentId: contentId, mediaUrls: const [], linkUrls: [url]));
          continue;
        }
        summaries.add(
          ContentUrlSummary(
            contentId: contentId,
            mediaUrls: row.readWithConverter<List<String>, String>(contents.mediaUrls)!,
            linkUrls: const [],
          ),
        );
      }
      return summaries;
    });
  }

  /// Voir [ContentRepository.deleteAll].
  @override
  Future<void> deleteAll() {
    return guardDrift(_source, () async {
      await _database.delete(_database.contents).go();
    });
  }

  /// Le groupe d'un contenu (non vu, puis les autres) est une expression SQL, pour que le tri et la reprise après le
  /// curseur se fassent dans la même requête.
  @override
  Future<CursorPage<ContentDetailed>> getHomeFeedPage({
    required DateTime feedStartedAt,
    required String? after,
    required int limit,
  }) {
    return guardDrift(_source, () async {
      final contents = _database.contents;
      final isViewed = _isViewedBefore(feedStartedAt);
      final isRead = contents.origin.equals(ContentOrigin.owned.value) | isViewed;
      final query = _detailedSelect(isViewed)
        ..where(contents.storedAt.isSmallerOrEqualValue(feedStartedAt.millisecondsSinceEpoch));
      if (after != null) {
        final cursor = _FeedCursor.decode(after);
        final isAfterInGroup = _isAfterByScore(cursor.displayScore, cursor.id);
        if (cursor.isRead) {
          query.where(isRead & isAfterInGroup);
        }
        if (!cursor.isRead) {
          query.where(isRead | isAfterInGroup);
        }
      }
      query
        ..orderBy([OrderingTerm.asc(isRead), OrderingTerm.desc(contents.displayScore), OrderingTerm.asc(contents.id)])
        ..limit(limit + 1);

      final items = [for (final row in await query.get()) _toDetailed(row, isViewed)];
      if (items.length <= limit) {
        return CursorPage(items: items, nextCursor: null);
      }
      final pageItems = items.take(limit).toList();
      final last = pageItems.last;
      final nextCursor = _FeedCursor(
        isRead: last.content.isOwned || last.isViewed,
        displayScore: last.content.displayScore,
        id: last.content.id,
      ).encode();
      return CursorPage(items: pageItems, nextCursor: nextCursor);
    });
  }

  /// La recherche se fait avec `instr` sur des colonnes déjà en minuscules plutôt qu'avec `LIKE`, qui ne gère la casse
  /// que pour l'ASCII et donnerait un sens aux `%` et `_` saisis.
  @override
  Future<CursorPage<ContentDetailed>> getPageMatchingTitleOrFlair(
    String query, {
    required String? after,
    required int limit,
  }) {
    final contents = _database.contents;
    // Les flairs sont stockés normalisés (sans `/`, en minuscules) : la saisie l'est aussi pour que `/france` trouve
    // le flair `france`.
    final titleQuery = query.toLowerCase();
    final flairQuery = query.toFlair() ?? titleQuery;
    final isMatching =
        FunctionCallExpression<int>('instr', [
          contents.searchTitle,
          Variable<String>(titleQuery),
        ]).isBiggerThanValue(0) |
        FunctionCallExpression<int>('instr', [contents.flair, Variable<String>(flairQuery)]).isBiggerThanValue(0);
    return _pageByScore(isMatching, after, limit);
  }

  /// Voir [ContentRepository.getPageByFlair].
  @override
  Future<CursorPage<ContentDetailed>> getPageByFlair(String flair, {required String? after, required int limit}) {
    return _pageByScore(_database.contents.flair.equals(flair), after, limit);
  }

  /// Voir [ContentRepository.getPageBySignatures].
  @override
  Future<CursorPage<ContentDetailed>> getPageBySignatures(
    Set<String> signatureIds, {
    required String? after,
    required int limit,
  }) {
    return _pageByScore(_database.contents.signatureId.isIn(signatureIds), after, limit);
  }

  /// Voir [ContentRepository.getAllDetailedByOrigin].
  @override
  Future<List<ContentDetailed>> getAllDetailedByOrigin(ContentOrigin origin) {
    return guardDrift(_source, () async {
      final contents = _database.contents;
      final query = _detailedSelect(_isViewedEver)
        ..where(contents.origin.equals(origin.value))
        ..orderBy([OrderingTerm.desc(contents.createdAt), OrderingTerm.asc(contents.id)]);
      return [for (final row in await query.get()) _toDetailed(row, _isViewedEver)];
    });
  }

  /// Voir [ContentRepository.getById].
  @override
  Future<Content?> getById(String id) {
    return guardDrift(_source, () async {
      final query = _database.select(_database.contents)..where((table) => table.id.equals(id));
      final row = await query.getSingleOrNull();
      if (row == null) {
        return null;
      }
      return ContentDriftMapper.toEntity(row);
    });
  }

  /// Voir [ContentRepository.getDetailedByIds].
  @override
  Future<List<ContentDetailed>> getDetailedByIds(List<String> ids) {
    return guardDrift(_source, () async {
      if (ids.isEmpty) {
        return const [];
      }
      final query = _detailedSelect(_isViewedEver)..where(_database.contents.id.isIn(ids));
      final byId = {
        for (final detailed in [for (final row in await query.get()) _toDetailed(row, _isViewedEver)])
          detailed.content.id: detailed,
      };
      return [for (final id in ids) ?byId[id]];
    });
  }

  /// Voir [ContentRepository.getExistingIds].
  @override
  Future<Set<String>> getExistingIds(Set<String> ids) {
    return guardDrift(_source, () async {
      if (ids.isEmpty) {
        return <String>{};
      }
      final contents = _database.contents;
      final query = _database.selectOnly(contents)
        ..addColumns([contents.id])
        ..where(contents.id.isIn(ids));
      return {for (final row in await query.get()) row.read(contents.id)!};
    });
  }

  /// Voir [ContentRepository.getTopSummariesByBroadcastScore].
  @override
  Future<List<ContentSummary>> getTopSummariesByBroadcastScore(int limit) {
    return guardDrift(_source, () async {
      final contents = _database.contents;
      final query = _summarySelect()
        ..orderBy([OrderingTerm.desc(contents.broadcastScore), OrderingTerm.asc(contents.id)])
        ..limit(limit);
      return [for (final row in await query.get()) _toSummary(row)];
    });
  }

  /// Seuls les identifiants des candidats sont lus et mélangés, triés au préalable pour qu'un même générateur donne
  /// toujours le même tirage ; seuls les contenus tirés sont ensuite résumés.
  @override
  Future<List<ContentSummary>> getRandomSummariesExcluding(int limit, Set<String> excludedIds, Random random) {
    return guardDrift(_source, () async {
      if (limit <= 0) {
        return const [];
      }
      final contents = _database.contents;
      final idsQuery = _database.selectOnly(contents)
        ..addColumns([contents.id])
        ..orderBy([OrderingTerm.asc(contents.id)]);
      if (excludedIds.isNotEmpty) {
        idsQuery.where(contents.id.isNotIn(excludedIds));
      }
      final candidateIds = [for (final row in await idsQuery.get()) row.read(contents.id)!]..shuffle(random);
      final drawnIds = candidateIds.take(limit).toList();
      final byId = {for (final summary in await _summariesByIds(drawnIds.toSet())) summary.contentId: summary};
      return [for (final id in drawnIds) ?byId[id]];
    });
  }

  /// Voir [ContentRepository.getSummariesByIds].
  @override
  Future<List<ContentSummary>> getSummariesByIds(Set<String> ids) {
    return guardDrift(_source, () {
      return _summariesByIds(ids);
    });
  }

  /// Voir [ContentRepository.getReceivedSummariesBySurvival].
  @override
  Future<List<ContentSummary>> getReceivedSummariesBySurvival(int limit) {
    return guardDrift(_source, () async {
      final contents = _database.contents;
      final query = _summarySelect()
        ..where(contents.origin.equals(ContentOrigin.owned.value).not())
        ..orderBy([
          OrderingTerm.asc(contents.survivalScore),
          OrderingTerm.asc(contents.createdAt),
          OrderingTerm.asc(contents.id),
        ])
        ..limit(limit);
      return [for (final row in await query.get()) _toSummary(row)];
    });
  }

  /// Une seule transaction (un `batch`) : la trace et la suppression sont écrites ensemble ou pas du tout. Les
  /// réactions, commentaires et traces d'affichage partent par les clés étrangères `ON DELETE CASCADE`.
  @override
  Future<void> deleteManyAsSeen(List<String> ids, DateTime seenAt) {
    return guardDrift(_source, () async {
      if (ids.isEmpty) {
        return;
      }
      await _database.batch((batch) {
        batch.insertAllOnConflictUpdate(_database.seenContents, [
          for (final id in ids)
            SeenContentDriftMapper.toCompanion(SeenContent(id: id, createdAt: seenAt, updatedAt: seenAt)),
        ]);
        for (var start = 0; start < ids.length; start += _maxIdsPerStatement) {
          final chunk = ids.sublist(start, min(start + _maxIdsPerStatement, ids.length));
          batch.deleteWhere(_database.contents, (table) => table.id.isIn(chunk));
        }
      });
    });
  }

  /// Appelée à chaque frappe : seule la colonne du flair est lue. La comparaison du début se fait avec `substr` plutôt
  /// qu'avec `LIKE`, qui donnerait un sens aux `%` et `_` saisis.
  @override
  Future<List<String>> getFlairsStartingWith(String prefix) {
    return guardDrift(_source, () async {
      final contents = _database.contents;
      final query = _database.selectOnly(contents)
        ..addColumns([contents.flair])
        ..where(contents.flair.substr(1, prefix.length).equals(prefix));
      return [for (final row in await query.get()) row.read(contents.flair)!];
    });
  }

  /// Écrit un score par contenu de [scoresById] en un seul `batch`, donc en une seule transaction.
  ///
  /// Chaque mise à jour n'écrit que la colonne du score : réécrire toute la ligne réécrirait aussi le dessin d'un
  /// contenu dessiné, pour rien. Toutes les mises à jour partagent la même requête préparée.
  ///
  /// - [scoresById] : nouveau score, par identifiant de contenu.
  /// - [toCompanion] : construit la mise à jour d'une ligne, réduite à la colonne du score.
  Future<void> _updateScores(Map<String, double> scoresById, ContentsCompanion Function(double score) toCompanion) {
    return guardDrift(_source, () async {
      if (scoresById.isEmpty) {
        return;
      }
      await _database.batch((batch) {
        for (final entry in scoresById.entries) {
          batch.update(_database.contents, toCompanion(entry.value), where: (table) => table.id.equals(entry.key));
        }
      });
    });
  }

  /// Retourne la provenance stockée sous [value].
  ///
  /// Une valeur inconnue lève une [DataException] : elle ne peut venir que d'une écriture corrompue.
  ///
  /// - [value] : valeur entière persistée de la provenance.
  ContentOrigin _originOf(int value) {
    for (final origin in ContentOrigin.values) {
      if (origin.value == value) {
        return origin;
      }
    }
    throw DataException(_source, 'provenance "$value" non supportée');
  }

  /// Retourne la ligne à insérer pour [entity], enregistrée à [storedAt].
  ///
  /// - [entity] : contenu à insérer.
  /// - [storedAt] : date d'enregistrement sur ce téléphone.
  ContentsCompanion _insertCompanion(Content entity, DateTime storedAt) {
    return ContentDriftMapper.toCompanion(entity, storedAt: storedAt);
  }

  /// Retourne la mise à jour appliquée quand [entity] existe déjà : tous ses champs sont remplacés, sauf sa date
  /// d'enregistrement.
  ///
  /// Un remplacement (`INSERT OR REPLACE`) supprimerait la ligne, et avec elle, par cascade, ses réactions et ses
  /// commentaires.
  ///
  /// - [entity] : contenu inséré.
  DoUpdate<Contents, ContentRow> _upsert(Content entity) {
    return DoUpdate((_) => ContentDriftMapper.toCompanion(entity));
  }

  /// Retourne l'expression indiquant si le contenu de la ligne lue a été vu au plus tard à [before].
  ///
  /// - [before] : date limite des vues retenues, `null` pour toutes.
  Expression<bool> _isViewedBefore(DateTime? before) {
    final viewedContents = _database.viewedContents;
    final query = _database.selectOnly(viewedContents)
      ..addColumns([viewedContents.id])
      ..where(viewedContents.id.equalsExp(_database.contents.id));
    if (before != null) {
      query.where(viewedContents.createdAt.isSmallerOrEqualValue(before.millisecondsSinceEpoch));
    }
    return existsQuery(query);
  }

  /// Retourne la lecture des contenus détaillés : chaque contenu, la signature de son auteur, son nombre de réactions
  /// et [isViewed].
  ///
  /// La signature est jointe à gauche : un contenu anonyme, ou dont la signature n'est plus connue, est lu sans elle.
  ///
  /// - [isViewed] : expression de la trace d'affichage à lire avec chaque contenu.
  JoinedSelectStatement<HasResultSet, dynamic> _detailedSelect(Expression<bool> isViewed) {
    final contents = _database.contents;
    final signatures = _database.signatures;
    return _database.select(contents).join([leftOuterJoin(signatures, signatures.id.equalsExp(contents.signatureId))])
      ..addColumns([_reactionCount, isViewed]);
  }

  /// Retourne le contenu détaillé d'une ligne lue par [_detailedSelect].
  ///
  /// - [row] : ligne lue.
  /// - [isViewed] : expression de la trace d'affichage passée à [_detailedSelect].
  ContentDetailed _toDetailed(TypedResult row, Expression<bool> isViewed) {
    final signatureRow = row.readTableOrNull(_database.signatures);
    return ContentDetailed(
      content: ContentDriftMapper.toEntity(row.readTable(_database.contents)),
      signature: signatureRow == null ? null : SignatureDriftMapper.toEntity(signatureRow),
      reactionCount: row.read(_reactionCount) ?? 0,
      isViewed: row.read(isViewed) ?? false,
    );
  }

  /// Retourne l'expression vraie pour les contenus placés après ([displayScore], [id]) dans l'ordre des listes : score
  /// d'affichage décroissant, puis identifiant croissant.
  ///
  /// - [displayScore] : score d'affichage du dernier contenu de la page précédente.
  /// - [id] : identifiant du dernier contenu de la page précédente.
  Expression<bool> _isAfterByScore(double displayScore, String id) {
    final contents = _database.contents;
    return contents.displayScore.isSmallerThanValue(displayScore) |
        (contents.displayScore.equals(displayScore) & contents.id.isBiggerThanValue(id));
  }

  /// Retourne une page des contenus détaillés vérifiant [filter], du plus fort score d'affichage au plus faible.
  ///
  /// - [filter] : condition des contenus retenus.
  /// - [after] : curseur de la page précédente, `null` pour la première page.
  /// - [limit] : nombre maximal de contenus de la page.
  Future<CursorPage<ContentDetailed>> _pageByScore(Expression<bool> filter, String? after, int limit) {
    return guardDrift(_source, () async {
      final contents = _database.contents;
      final query = _detailedSelect(_isViewedEver)..where(filter);
      if (after != null) {
        final cursor = _ScoreCursor.decode(after);
        query.where(_isAfterByScore(cursor.displayScore, cursor.id));
      }
      query
        ..orderBy([OrderingTerm.desc(contents.displayScore), OrderingTerm.asc(contents.id)])
        ..limit(limit + 1);

      final items = [for (final row in await query.get()) _toDetailed(row, _isViewedEver)];
      if (items.length <= limit) {
        return CursorPage(items: items, nextCursor: null);
      }
      final pageItems = items.take(limit).toList();
      final last = pageItems.last.content;
      return CursorPage(
        items: pageItems,
        nextCursor: _ScoreCursor(displayScore: last.displayScore, id: last.id).encode(),
      );
    });
  }

  /// Retourne la lecture des résumés de contenus : poids, nombre de réactions et date de la plus récente, groupés par
  /// contenu.
  JoinedSelectStatement<HasResultSet, dynamic> _summarySelect() {
    final contents = _database.contents;
    final reactions = _database.reactions;
    return _database.selectOnly(contents).join([
        leftOuterJoin(reactions, reactions.contentId.equalsExp(contents.id), useColumns: false),
      ])
      ..addColumns([contents.id, contents.sizeInBytes, _summaryReactionCount, _summaryLatestReactionAt])
      ..groupBy([contents.id]);
  }

  /// Retourne le résumé d'une ligne lue par [_summarySelect].
  ///
  /// - [row] : ligne lue.
  ContentSummary _toSummary(TypedResult row) {
    final latestReactionAt = row.read(_summaryLatestReactionAt);
    return ContentSummary(
      contentId: row.read(_database.contents.id)!,
      sizeInBytes: row.read(_database.contents.sizeInBytes)!,
      reactionCount: row.read(_summaryReactionCount) ?? 0,
      latestReactionAt: latestReactionAt == null ? null : DateTime.fromMillisecondsSinceEpoch(latestReactionAt),
    );
  }

  /// Retourne le résumé des contenus présents parmi [ids], sans traduire les erreurs.
  ///
  /// - [ids] : contenus à résumer.
  Future<List<ContentSummary>> _summariesByIds(Set<String> ids) async {
    if (ids.isEmpty) {
      return const [];
    }
    final query = _summarySelect()..where(_database.contents.id.isIn(ids));
    return [for (final row in await query.get()) _toSummary(row)];
  }
}

/// Curseur des listes triées par score d'affichage : la position du dernier contenu de la page.
class _ScoreCursor {
  /// Crée un [_ScoreCursor].
  ///
  /// - [displayScore] : score d'affichage du dernier contenu de la page.
  /// - [id] : identifiant du dernier contenu de la page.
  const _ScoreCursor({required this.displayScore, required this.id});

  /// Relit un curseur produit par [encode].
  ///
  /// Un curseur illisible lève une [DataException] : il ne peut venir que d'un appelant qui l'a modifié.
  ///
  /// - [cursor] : curseur opaque.
  factory _ScoreCursor.decode(String cursor) {
    final fields = _decodeCursorFields(cursor);
    if (fields.length != 2) {
      throw DataException(_source, 'curseur invalide : $cursor');
    }
    return _ScoreCursor(displayScore: double.parse(fields[0]), id: fields[1]);
  }

  /// Score d'affichage du dernier contenu de la page.
  final double displayScore;

  /// Identifiant du dernier contenu de la page.
  final String id;

  /// Encode ce curseur en texte opaque.
  String encode() {
    return _encodeCursorFields(['$displayScore', id]);
  }
}

/// Curseur du fil d'accueil : la position du dernier contenu de la page, groupe compris.
class _FeedCursor {
  /// Crée un [_FeedCursor].
  ///
  /// - [isRead] : indique si le dernier contenu de la page est dans le groupe des contenus déjà vus ou possédés.
  /// - [displayScore] : score d'affichage du dernier contenu de la page.
  /// - [id] : identifiant du dernier contenu de la page.
  const _FeedCursor({required this.isRead, required this.displayScore, required this.id});

  /// Relit un curseur produit par [encode].
  ///
  /// Un curseur illisible lève une [DataException] : il ne peut venir que d'un appelant qui l'a modifié.
  ///
  /// - [cursor] : curseur opaque.
  factory _FeedCursor.decode(String cursor) {
    final fields = _decodeCursorFields(cursor);
    if (fields.length != 3) {
      throw DataException(_source, 'curseur invalide : $cursor');
    }
    return _FeedCursor(isRead: fields[0] == '1', displayScore: double.parse(fields[1]), id: fields[2]);
  }

  /// Indique si le dernier contenu de la page est dans le groupe des contenus déjà vus ou possédés.
  final bool isRead;

  /// Score d'affichage du dernier contenu de la page.
  final double displayScore;

  /// Identifiant du dernier contenu de la page.
  final String id;

  /// Encode ce curseur en texte opaque.
  String encode() {
    return _encodeCursorFields([isRead ? '1' : '0', '$displayScore', id]);
  }
}

/// Encode les champs d'un curseur en texte opaque, sûr dans une URL.
///
/// Le score est écrit en texte : la représentation la plus courte d'un `double` en Dart se relit à l'identique, ce
/// qui garantit l'égalité exacte avec la valeur stockée lors de la reprise.
///
/// - [fields] : champs du curseur.
String _encodeCursorFields(List<String> fields) {
  return base64Url.encode(utf8.encode(jsonEncode(fields)));
}

/// Relit les champs d'un curseur encodé par [_encodeCursorFields].
///
/// - [cursor] : curseur opaque.
List<String> _decodeCursorFields(String cursor) {
  try {
    return (jsonDecode(utf8.decode(base64Url.decode(cursor))) as List<dynamic>).cast<String>();
  } on FormatException catch (error) {
    throw DataException(_source, error);
  }
}
