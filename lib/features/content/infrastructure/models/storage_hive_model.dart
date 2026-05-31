import 'package:bedbug/features/content/domain/entities/storage.dart';
import 'package:bedbug/features/content/domain/enums/cleanup_strategy.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/infrastructure/hive_type_ids.dart';
import 'package:hive_ce/hive.dart';

part 'storage_hive_model.g.dart';

/// DTO Hive représentant un [Storage] persisté localement.
@HiveType(typeId: HiveTypeIds.storage)
class StorageHiveModel extends HiveObject {
  /// Crée un [StorageHiveModel].
  StorageHiveModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.maxSizeInBytes,
    required this.strategy,
  });

  /// Crée un [StorageHiveModel] depuis une entité [Storage].
  factory StorageHiveModel.fromEntity(Storage entity) {
    return StorageHiveModel(
      id: entity.id,
      createdAt: entity.createdAt.millisecondsSinceEpoch,
      updatedAt: entity.updatedAt.millisecondsSinceEpoch,
      maxSizeInBytes: entity.maxSizeInBytes,
      strategy: entity.strategy.value,
    );
  }

  /// Identifiant unique de la configuration.
  @HiveField(0)
  final String id;

  /// Date de création en millisecondes depuis l'époque Unix.
  @HiveField(1)
  final int createdAt;

  /// Date de mise à jour en millisecondes depuis l'époque Unix.
  @HiveField(2)
  final int updatedAt;

  /// Taille maximale allouée aux contenus, en octets.
  @HiveField(3)
  final int maxSizeInBytes;

  /// Stratégie de nettoyage encodée comme valeur de [CleanupStrategy].
  @HiveField(4)
  final int strategy;

  /// Convertit ce modèle en entité [Storage].
  Storage toEntity() {
    try {
      return Storage(
        id: id,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
        maxSizeInBytes: maxSizeInBytes,
        strategy: CleanupStrategy.values.firstWhere((s) => s.value == strategy),
      );
    } catch (error) {
      throw DataException('StorageHiveModel', error);
    }
  }
}
