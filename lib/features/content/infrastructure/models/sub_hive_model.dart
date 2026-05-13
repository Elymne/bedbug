import 'package:bedbug/features/content/domain/entities/sub.dart';
import 'package:bedbug/shared/infrastructure/hive_type_ids.dart';
import 'package:hive_ce/hive.dart';

part 'sub_hive_model.g.dart';

/// DTO Hive représentant un [Sub] persisté localement.
@HiveType(typeId: HiveTypeIds.sub)
class SubHiveModel extends HiveObject {
  /// Crée un [SubHiveModel].
  SubHiveModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.description,
  });

  /// Crée un [SubHiveModel] depuis une entité [Sub].
  factory SubHiveModel.fromEntity(Sub entity) {
    return SubHiveModel(
      id: entity.id,
      createdAt: entity.createdAt.millisecondsSinceEpoch,
      updatedAt: entity.updatedAt.millisecondsSinceEpoch,
      name: entity.name,
      description: entity.description,
    );
  }

  /// Identifiant unique du sub.
  @HiveField(0)
  final String id;

  /// Date de création en millisecondes depuis l'époque Unix.
  @HiveField(1)
  final int createdAt;

  /// Date de mise à jour en millisecondes depuis l'époque Unix.
  @HiveField(2)
  final int updatedAt;

  /// Nom du sub.
  @HiveField(3)
  final String name;

  /// Description du sub.
  @HiveField(4)
  final String description;

  /// Convertit ce modèle en entité [Sub].
  Sub toEntity() {
    return Sub(
      id: id,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
      name: name,
      description: description,
    );
  }
}
