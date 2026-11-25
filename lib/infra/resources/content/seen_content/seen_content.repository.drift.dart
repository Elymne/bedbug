import 'package:bedbug/infra/resources/content/seen_content/seen_content.entity.dart';
import 'package:bedbug/infra/resources/content/seen_content/seen_content.mapper.drift.dart';
import 'package:bedbug/infra/resources/content/seen_content/seen_content.repository.dart';
import 'package:bedbug/infra/resources/drift.database.dart';
import 'package:bedbug/infra/resources/drift.guard.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nom du repository, repris dans ses exceptions.
const String _source = 'DriftSeenContentRepository';

/// Provider du [DriftSeenContentRepository].
final seenContentRepositoryProvider = Provider<SeenContentRepository>((ref) {
  return DriftSeenContentRepository(ref.read(appDatabaseProvider));
});

/// Implémentation de [SeenContentRepository] sur la table `seen_contents`, sans clé étrangère vers les contenus pour
/// que la trace survive à leur suppression.
class DriftSeenContentRepository implements SeenContentRepository {
  /// Crée un [DriftSeenContentRepository].
  ///
  /// - [_database] : base SQLite de l'app.
  DriftSeenContentRepository(this._database);

  /// Base SQLite de l'app.
  final AppDatabase _database;

  /// Une trace déjà présente est remplacée : sa date repart de zéro, comme sa rétention.
  @override
  Future<void> addMany(Iterable<SeenContent> entities) {
    return guardDrift(_source, () async {
      await _database.batch((batch) {
        batch.insertAllOnConflictUpdate(_database.seenContents, [
          for (final entity in entities) SeenContentDriftMapper.toCompanion(entity),
        ]);
      });
    });
  }

  /// Voir [SeenContentRepository.getSeenAmong].
  @override
  Future<Set<String>> getSeenAmong(Set<String> ids) {
    return guardDrift(_source, () async {
      if (ids.isEmpty) {
        return <String>{};
      }
      final seenContents = _database.seenContents;
      final query = _database.selectOnly(seenContents)
        ..addColumns([seenContents.id])
        ..where(seenContents.id.isIn(ids));
      return {for (final row in await query.get()) row.read(seenContents.id)!};
    });
  }

  /// Voir [SeenContentRepository.deleteSeenBefore].
  @override
  Future<void> deleteSeenBefore(DateTime date) {
    return guardDrift(_source, () async {
      final statement = _database.delete(_database.seenContents)
        ..where((table) => table.createdAt.isSmallerThanValue(date.millisecondsSinceEpoch));
      await statement.go();
    });
  }
}
