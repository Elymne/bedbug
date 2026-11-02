import 'package:bedbug/resources/content/storage/cleanup_strategy.enum.dart';
import 'package:bedbug/resources/content/storage/storage.value_object.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/hive.type_ids.dart';
import 'package:hive_ce/hive.dart';

part 'storage.model.hive.g.dart';

/// DTO Hive représentant un [Storage] persisté localement.
@HiveType(typeId: HiveTypeIds.storage)
class StorageHiveModel extends HiveObject {
  /// Crée un [StorageHiveModel].
  ///
  /// - [maxSizeInBytes] : taille maximale allouée aux contenus, en octets.
  /// - [currentSizeInBytes] : taille actuellement occupée par les contenus, en octets.
  /// - [strategy] : stratégie de nettoyage encodée comme valeur de [CleanupStrategy].
  StorageHiveModel({required this.maxSizeInBytes, required this.currentSizeInBytes, required this.strategy});

  /// Crée un [StorageHiveModel] depuis un [Storage].
  ///
  /// - [storage] : configuration à persister.
  factory StorageHiveModel.fromEntity(Storage storage) {
    return StorageHiveModel(
      maxSizeInBytes: storage.maxSizeInBytes,
      currentSizeInBytes: storage.currentSizeInBytes,
      strategy: storage.strategy.value,
    );
  }

  /// Taille maximale allouée aux contenus, en octets.
  @HiveField(0)
  final int maxSizeInBytes;

  /// Stratégie de nettoyage encodée comme valeur de [CleanupStrategy].
  @HiveField(1)
  final int strategy;

  /// Taille actuellement occupée par les contenus, en octets.
  @HiveField(2)
  final int currentSizeInBytes;

  /// Convertit ce modèle en [Storage].
  ///
  /// Lève une [DataException] si la stratégie enregistrée n'existe plus.
  Storage toEntity() {
    try {
      return Storage(
        maxSizeInBytes: maxSizeInBytes,
        currentSizeInBytes: currentSizeInBytes,
        strategy: CleanupStrategy.values.firstWhere((candidate) => candidate.value == strategy),
      );
    } catch (error) {
      throw DataException('StorageHiveModel', error);
    }
  }
}
