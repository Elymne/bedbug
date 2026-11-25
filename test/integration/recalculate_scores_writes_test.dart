import 'dart:math' as math;

import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/infra/resources/content/content/content.entity.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.drift.dart';
import 'package:bedbug/infra/resources/content/content/content_origin.enum.dart';
import 'package:bedbug/infra/resources/content/content/drawing_content.entity.dart';
import 'package:bedbug/infra/resources/content/content/link_content.entity.dart';
import 'package:bedbug/infra/resources/content/content/text_content.entity.dart';
import 'package:bedbug/infra/resources/content/drawing/drawing.config.dart';
import 'package:bedbug/infra/resources/content/drawing/drawing.value_object.dart';
import 'package:bedbug/infra/resources/drift.database.dart';
import 'package:bedbug/logic/usecases/exchange/recalculate_broadcast_scores/recalculate_broadcast_scores.usecase.dart';
import 'package:bedbug/logic/usecases/feed/recalculate_display_scores/recalculate_display_scores.usecase.dart';
import 'package:bedbug/logic/usecases/storage/recalculate_survival_scores/recalculate_survival_scores.usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/drift_test_helper.dart';

/// Colonnes de `contents` qui ne sont pas des scores : aucun recalcul ne doit les écrire.
const String _nonScoreColumns =
    'id, created_at, updated_at, stored_at, signature_id, type, origin, bounce, title, search_title, body, url, '
    'flair, size_in_bytes, og_image_url, og_title, og_description, tag_values, media_urls, media_kinds, drawing_data';

/// Score attendu d'un contenu reçu, selon la formule d'origine des trois recalculs : décroissance par demi-vie, plus
/// (ou moins) une part plafonnée des rebonds, bornée à [0, 1].
///
/// - [now] : date du calcul.
/// - [content] : contenu dont on calcule le score.
/// - [halfLifeDays] : demi-vie du score, en jours.
/// - [bounceSign] : `1` pour un bonus de rebonds, `-1` pour une pénalité.
double _expectedScore(DateTime now, Content content, double halfLifeDays, int bounceSign) {
  final ageDays = now.difference(content.createdAt).inHours / 24;
  final ageScore = math.pow(0.5, ageDays / halfLifeDays).toDouble();
  final bounceShare = 0.2 * (math.min(content.bounce, 10) / 10);
  return (ageScore + bounceSign * bounceShare).clamp(0.0, 1.0);
}

/// Construit les contenus du test, tous à scores nuls : un dessin, un texte et un lien reçus, et un texte de
/// l'utilisateur.
///
/// - [now] : date de référence des âges.
List<Content> _buildContents(DateTime now) {
  const stroke = DrawingStroke(
    layer: 1,
    colorIndex: 0,
    brush: DrawingBrush.pen,
    size: 1,
    seed: 1,
    points: [DrawingPoint(1, 1), DrawingPoint(2, 2)],
  );
  return [
    DrawingContent(
      id: 'dessin',
      createdAt: now.subtract(const Duration(days: 5, hours: 3)),
      updatedAt: now.subtract(const Duration(days: 5)),
      signatureId: 'pair',
      flair: 'test',
      origin: ContentOrigin.public,
      broadcastScore: 0,
      survivalScore: 0,
      displayScore: 0,
      bounce: 3,
      sizeInBytes: 100,
      drawing: const Drawing(palette: defaultDrawingPalette, operations: [stroke]),
      title: 'Dessin',
    ),
    TextContent(
      id: 'texte',
      createdAt: now.subtract(const Duration(days: 40)),
      updatedAt: now.subtract(const Duration(days: 40)),
      signatureId: 'pair',
      flair: 'test',
      origin: ContentOrigin.favorited,
      broadcastScore: 0,
      survivalScore: 0,
      displayScore: 0,
      bounce: 0,
      sizeInBytes: 10,
      title: 'Texte',
      body: 'Corps',
    ),
    LinkContent(
      id: 'lien',
      createdAt: now.subtract(const Duration(days: 2, hours: 7)),
      updatedAt: now.subtract(const Duration(days: 2)),
      signatureId: 'pair',
      flair: 'test',
      origin: ContentOrigin.subscribed,
      broadcastScore: 0,
      survivalScore: 0,
      displayScore: 0,
      bounce: 20,
      sizeInBytes: 10,
      title: 'Lien',
      url: 'https://github.com/a',
    ),
    TextContent(
      id: 'mien',
      createdAt: now.subtract(const Duration(days: 400)),
      updatedAt: now.subtract(const Duration(days: 400)),
      signatureId: 'local',
      flair: 'test',
      origin: ContentOrigin.owned,
      broadcastScore: 0,
      survivalScore: 0,
      displayScore: 0,
      bounce: 0,
      sizeInBytes: 10,
      title: 'Mien',
      body: 'Corps',
    ),
  ];
}

void main() {
  late ProviderContainer container;
  late AppDatabase database;

  setUp(() async {
    container = createTestContainer();
    database = container.read(appDatabaseProvider);
    // Journalise toute mise à jour qui nomme une colonne autre qu'un score, même pour y réécrire la même valeur.
    await database.customStatement('CREATE TABLE non_score_writes (content_id TEXT NOT NULL)');
    await database.customStatement(
      'CREATE TRIGGER watch_non_score_writes AFTER UPDATE OF $_nonScoreColumns ON contents '
      'BEGIN INSERT INTO non_score_writes VALUES (new.id); END',
    );
    await database.customStatement('CREATE TABLE score_writes (content_id TEXT NOT NULL)');
    await database.customStatement(
      'CREATE TRIGGER watch_score_writes AFTER UPDATE OF broadcast_score, survival_score, display_score ON contents '
      'BEGIN INSERT INTO score_writes VALUES (new.id); END',
    );
  });

  tearDown(() async {
    container.dispose();
  });

  /// Retourne les identifiants journalisés dans [table], dans l'ordre des écritures.
  ///
  /// - [table] : table de journal lue.
  Future<List<String>> loggedIds(String table) async {
    final rows = await database.customSelect('SELECT content_id FROM $table').get();
    return [for (final row in rows) row.read<String>('content_id')];
  }

  /// Retourne les lignes brutes de `contents`, par identifiant.
  Future<Map<String, ContentRow>> rawRows() async {
    final rows = await database.select(database.contents).get();
    return {for (final row in rows) row.id: row};
  }

  test('les trois recalculs donnent les scores de la formule d\'origine, et laissent les contenus owned', () async {
    final now = DateTime.now();
    final contents = _buildContents(now);
    await container.read(contentRepositoryProvider).addMany(contents);

    expect((await container.read(recalculateBroadcastScoresUsecaseProvider)(const NoParams())).isSuccess, isTrue);
    expect((await container.read(recalculateSurvivalScoresUsecaseProvider)(const NoParams())).isSuccess, isTrue);
    expect((await container.read(recalculateDisplayScoresUsecaseProvider)(const NoParams())).isSuccess, isTrue);

    final computedAt = DateTime.now();
    final rows = await rawRows();
    for (final content in contents.where((content) => content.origin != ContentOrigin.owned)) {
      final row = rows[content.id]!;
      expect(row.broadcastScore, _expectedScore(computedAt, content, content.origin.broadcastHalfLifeDays, -1));
      expect(row.survivalScore, _expectedScore(computedAt, content, content.origin.survivalHalfLifeDays, 1));
      expect(row.displayScore, _expectedScore(computedAt, content, content.origin.displayHalfLifeDays, 1));
    }
    expect(rows['mien']!.broadcastScore, 0);
    expect(rows['mien']!.survivalScore, 0);
    expect(rows['mien']!.displayScore, 0);
  });

  test('n\'écrit que les colonnes de score : dessin, dates et textes restent intacts', () async {
    final now = DateTime.now();
    await container.read(contentRepositoryProvider).addMany(_buildContents(now));
    final before = await rawRows();

    await container.read(recalculateBroadcastScoresUsecaseProvider)(const NoParams());
    await container.read(recalculateSurvivalScoresUsecaseProvider)(const NoParams());
    await container.read(recalculateDisplayScoresUsecaseProvider)(const NoParams());

    expect(await loggedIds('non_score_writes'), isEmpty);
    expect((await loggedIds('score_writes')).toSet(), {'dessin', 'texte', 'lien'});
    final after = await rawRows();
    for (final id in before.keys) {
      final unscored = after[id]!.copyWith(
        broadcastScore: before[id]!.broadcastScore,
        survivalScore: before[id]!.survivalScore,
        displayScore: before[id]!.displayScore,
      );
      // Les listes des lignes générées ne se comparent pas par valeur : leur représentation, si.
      expect(unscored.toString(), before[id].toString());
    }
    expect(after['dessin']!.drawingData, before['dessin']!.drawingData);
    expect(after['dessin']!.storedAt, before['dessin']!.storedAt);
  });

  test('un second recalcul sans changement de score n\'écrit rien', () async {
    await container.read(contentRepositoryProvider).addMany(_buildContents(DateTime.now()));
    await container.read(recalculateDisplayScoresUsecaseProvider)(const NoParams());
    final writesAfterFirstRun = (await loggedIds('score_writes')).length;

    await container.read(recalculateDisplayScoresUsecaseProvider)(const NoParams());

    expect((await loggedIds('score_writes')).length, writesAfterFirstRun);
  });

  test('le résumé des scores ne lit que les contenus reçus', () async {
    // Dates stockées à la milliseconde : la référence l'est aussi pour comparer la date relue.
    final now = DateTime.fromMillisecondsSinceEpoch(DateTime.now().millisecondsSinceEpoch);
    await container.read(contentRepositoryProvider).addMany(_buildContents(now));

    final summaries = await container.read(contentRepositoryProvider).getReceivedScoreSummaries();

    expect(summaries.map((summary) => summary.contentId).toSet(), {'dessin', 'texte', 'lien'});
    final drawingSummary = summaries.firstWhere((summary) => summary.contentId == 'dessin');
    expect(drawingSummary.origin, ContentOrigin.public);
    expect(drawingSummary.bounce, 3);
    expect(drawingSummary.createdAt, now.subtract(const Duration(days: 5, hours: 3)));
  });

  test('une mise à jour de score ignore un contenu absent et écrit les autres', () async {
    await container.read(contentRepositoryProvider).addMany(_buildContents(DateTime.now()));

    await container.read(contentRepositoryProvider).updateSurvivalScores({'absent': 0.5, 'texte': 0.25});

    final rows = await rawRows();
    expect(rows['texte']!.survivalScore, 0.25);
    expect(rows.containsKey('absent'), isFalse);
  });
}
