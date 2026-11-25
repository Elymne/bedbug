import 'package:bedbug/infra/resources/content/storage/cleanup_strategy.enum.dart';
import 'package:bedbug/infra/resources/content/storage/storage.value_object.dart';
import 'package:bedbug/infra/resources/data.exception.dart';
import 'package:bedbug/infra/resources/drift.config.dart';
import 'package:bedbug/infra/resources/drift.database.dart';
import 'package:drift/drift.dart';

/// Conversion entre un [Storage] et la ligne unique de la table `storage_settings`.
abstract final class StorageDriftMapper {
  /// Reconstruit la configuration de la ligne.
  ///
  /// Lève une [DataException] si la stratégie enregistrée n'existe plus.
  ///
  /// [row] : ligne lue dans la table `storage_settings`.
  static Storage toEntity(StorageRow row) {
    try {
      return Storage(
        maxSizeInBytes: row.maxSizeInBytes,
        strategy: CleanupStrategy.values.firstWhere((candidate) => candidate.value == row.strategy),
      );
    } catch (error) {
      throw DataException('StorageDriftMapper', error);
    }
  }

  /// Construit la ligne unique, d'identifiant [singleRowId], à écrire pour une configuration.
  ///
  /// [entity] : configuration à écrire.
  static StorageSettingsCompanion toCompanion(Storage entity) {
    return StorageSettingsCompanion.insert(
      id: const Value(singleRowId),
      maxSizeInBytes: entity.maxSizeInBytes,
      strategy: entity.strategy.value,
    );
  }
}
