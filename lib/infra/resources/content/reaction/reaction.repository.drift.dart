import 'package:bedbug/infra/resources/content/reaction/reaction.entity.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.mapper.drift.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.repository.dart';
import 'package:bedbug/infra/resources/drift.database.dart';
import 'package:bedbug/infra/resources/drift.guard.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nom du repository, repris dans ses exceptions.
const String _source = 'DriftReactionRepository';

/// Provider du [DriftReactionRepository].
final reactionRepositoryProvider = Provider<ReactionRepository>((ref) {
  return DriftReactionRepository(ref.read(appDatabaseProvider));
});

/// Implémentation de [ReactionRepository] sur la table `reactions`, dont les lignes partent avec leur contenu par clé
/// étrangère.
class DriftReactionRepository implements ReactionRepository {
  /// Crée un [DriftReactionRepository].
  ///
  /// - [_database] : base SQLite de l'app.
  DriftReactionRepository(this._database);

  /// Base SQLite de l'app.
  final AppDatabase _database;

  /// Une réaction de même identifiant est mise à jour sur place, jamais supprimée puis réinsérée.
  @override
  Future<void> addOne(Reaction entity) {
    return guardDrift(_source, () async {
      await _database.into(_database.reactions).insertOnConflictUpdate(ReactionDriftMapper.toCompanion(entity));
    });
  }

  /// Voir [ReactionRepository.addMany].
  @override
  Future<void> addMany(List<Reaction> entities) {
    return guardDrift(_source, () async {
      await _database.batch((batch) {
        batch.insertAllOnConflictUpdate(_database.reactions, [
          for (final entity in entities) ReactionDriftMapper.toCompanion(entity),
        ]);
      });
    });
  }

  /// Un `batch` s'exécute dans une transaction. Les suppressions passent avant l'insertion : la réaction enregistrée
  /// peut reprendre l'identifiant d'une réaction supprimée.
  @override
  Future<void> addReplacing(Reaction entity, List<String> removedIds) {
    return guardDrift(_source, () async {
      await _database.batch((batch) {
        if (removedIds.isNotEmpty) {
          batch.deleteWhere(_database.reactions, (table) => table.id.isIn(removedIds));
        }
        batch.insertAllOnConflictUpdate(_database.reactions, [ReactionDriftMapper.toCompanion(entity)]);
      });
    });
  }

  /// Voir [ReactionRepository.getAllByContentId].
  @override
  Future<List<Reaction>> getAllByContentId(String contentId) {
    return guardDrift(_source, () async {
      final query = _database.select(_database.reactions)..where((table) => table.contentId.equals(contentId));
      return [for (final row in await query.get()) ReactionDriftMapper.toEntity(row)];
    });
  }

  /// Voir [ReactionRepository.getAllByContentIds].
  @override
  Future<List<Reaction>> getAllByContentIds(Set<String> contentIds) {
    return guardDrift(_source, () async {
      if (contentIds.isEmpty) {
        return const [];
      }
      final query = _database.select(_database.reactions)..where((table) => table.contentId.isIn(contentIds));
      return [for (final row in await query.get()) ReactionDriftMapper.toEntity(row)];
    });
  }

  /// Voir [ReactionRepository.getIdsByAuthor].
  @override
  Future<Set<String>> getIdsByAuthor(String authorId, Set<String> contentIds) {
    return guardDrift(_source, () async {
      if (contentIds.isEmpty) {
        return <String>{};
      }
      final reactions = _database.reactions;
      final query = _database.selectOnly(reactions)
        ..addColumns([reactions.id])
        ..where(reactions.authorId.equals(authorId) & reactions.contentId.isIn(contentIds));
      return {for (final row in await query.get()) row.read(reactions.id)!};
    });
  }

  /// Voir [ReactionRepository.countByContentId].
  @override
  Future<int> countByContentId(String contentId) {
    return guardDrift(_source, () async {
      final reactions = _database.reactions;
      final count = reactions.id.count();
      final query = _database.selectOnly(reactions)
        ..addColumns([count])
        ..where(reactions.contentId.equals(contentId));
      final row = await query.getSingle();
      return row.read(count) ?? 0;
    });
  }

  /// Voir [ReactionRepository.deleteMany].
  @override
  Future<void> deleteMany(List<String> ids) {
    return guardDrift(_source, () async {
      if (ids.isEmpty) {
        return;
      }
      await (_database.delete(_database.reactions)..where((table) => table.id.isIn(ids))).go();
    });
  }
}
