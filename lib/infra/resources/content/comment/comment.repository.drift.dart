import 'package:bedbug/infra/resources/content/comment/comment.entity.dart';
import 'package:bedbug/infra/resources/content/comment/comment.mapper.drift.dart';
import 'package:bedbug/infra/resources/content/comment/comment.repository.dart';
import 'package:bedbug/infra/resources/drift.database.dart';
import 'package:bedbug/infra/resources/drift.guard.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nom du repository, repris dans ses exceptions.
const String _source = 'DriftCommentRepository';

/// Provider du [DriftCommentRepository].
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return DriftCommentRepository(ref.read(appDatabaseProvider));
});

/// Implémentation de [CommentRepository] sur la table `comments`, dont les lignes partent avec leur contenu par clé
/// étrangère.
class DriftCommentRepository implements CommentRepository {
  /// Crée un [DriftCommentRepository].
  ///
  /// - [_database] : base SQLite de l'app.
  DriftCommentRepository(this._database);

  /// Base SQLite de l'app.
  final AppDatabase _database;

  /// Un commentaire de même identifiant est mis à jour sur place, jamais supprimé puis réinséré.
  @override
  Future<void> addOne(Comment entity) {
    return guardDrift(_source, () async {
      await _database.into(_database.comments).insertOnConflictUpdate(CommentDriftMapper.toCompanion(entity));
    });
  }

  /// La recherche du doublon, l'insertion et l'élagage se font dans une même transaction : un commentaire n'est jamais
  /// enregistré sans que le plafond de son contenu soit appliqué. L'élagage supprime en une requête les commentaires
  /// du contenu absents des [maxPerContent] plus récents, sans les relire ; à date égale, l'identifiant départage.
  @override
  Future<Comment> addOneKeepingLatest(Comment entity, {required int maxPerContent}) {
    return guardDrift(_source, () {
      return _database.transaction(() async {
        final comments = _database.comments;
        final duplicateQuery = _database.select(comments)
          ..where((table) => table.id.equals(entity.id) & table.contentId.equals(entity.contentId));
        final duplicate = await duplicateQuery.getSingleOrNull();
        if (duplicate != null) {
          return CommentDriftMapper.toEntity(duplicate);
        }

        await _database.into(comments).insertOnConflictUpdate(CommentDriftMapper.toCompanion(entity));

        final keptIds = _database.selectOnly(comments)
          ..addColumns([comments.id])
          ..where(comments.contentId.equals(entity.contentId))
          ..orderBy([OrderingTerm.desc(comments.createdAt), OrderingTerm.asc(comments.id)])
          ..limit(maxPerContent);
        final overflow = _database.delete(comments)
          ..where((table) => table.contentId.equals(entity.contentId) & table.id.isNotInQuery(keptIds));
        await overflow.go();
        return entity;
      });
    });
  }

  /// Voir [CommentRepository.getAllByContentId].
  @override
  Future<List<Comment>> getAllByContentId(String contentId) {
    return guardDrift(_source, () async {
      final query = _database.select(_database.comments)..where((table) => table.contentId.equals(contentId));
      return [for (final row in await query.get()) CommentDriftMapper.toEntity(row)];
    });
  }
}
