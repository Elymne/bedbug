import 'package:bedbug/infra/resources/content/storage/storage.mapper.drift.dart';
import 'package:bedbug/infra/resources/content/storage/storage.repository.dart';
import 'package:bedbug/infra/resources/content/storage/storage.value_object.dart';
import 'package:bedbug/infra/resources/drift.config.dart';
import 'package:bedbug/infra/resources/drift.database.dart';
import 'package:bedbug/infra/resources/drift.guard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nom du repository, repris dans ses exceptions.
const String _source = 'DriftStorageRepository';

/// Provider du [DriftStorageRepository].
final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return DriftStorageRepository(ref.read(appDatabaseProvider));
});

/// Implémentation de [StorageRepository] : la configuration dans la ligne unique de `storage_settings`, le poids
/// utilisé mesuré sur le fichier de la base.
class DriftStorageRepository implements StorageRepository {
  /// Crée un [DriftStorageRepository].
  ///
  /// - [_database] : base SQLite de l'app.
  DriftStorageRepository(this._database);

  /// Base SQLite de l'app.
  final AppDatabase _database;

  /// Lit la ligne [singleRowId], absente tant que la configuration n'a jamais été enregistrée.
  @override
  Future<Storage?> get() {
    return guardDrift(_source, () async {
      final query = _database.select(_database.storageSettings)..where((table) => table.id.equals(singleRowId));
      final row = await query.getSingleOrNull();
      if (row == null) {
        return null;
      }
      return StorageDriftMapper.toEntity(row);
    });
  }

  /// Écrit [storage] dans la ligne [singleRowId], créée au premier enregistrement puis mise à jour.
  @override
  Future<void> save(Storage storage) {
    return guardDrift(_source, () async {
      await _database.into(_database.storageSettings).insertOnConflictUpdate(StorageDriftMapper.toCompanion(storage));
    });
  }

  /// Voir [StorageRepository.getUsedSizeInBytes].
  @override
  Future<int> getUsedSizeInBytes() {
    return guardDrift(_source, _database.usedSizeInBytes);
  }

  /// Voir [StorageRepository.releaseFreePages].
  @override
  Future<void> releaseFreePages() {
    return guardDrift(_source, _database.releaseFreePages);
  }
}
