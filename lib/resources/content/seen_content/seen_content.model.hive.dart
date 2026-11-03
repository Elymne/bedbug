import 'package:bedbug/resources/content/seen_content/seen_content.entity.dart';
import 'package:bedbug/resources/hive.type_ids.dart';
import 'package:hive_ce/hive.dart';

part 'seen_content.model.hive.g.dart';

/// DTO Hive représentant un [SeenContent] persisté localement.
@HiveType(typeId: HiveTypeIds.seenContent)
class SeenContentHiveModel extends HiveObject {
  /// Crée un [SeenContentHiveModel].
  ///
  /// - [id] : identifiant du contenu.
  /// - [createdAt] : moment où le contenu a été reçu ou supprimé.
  /// - [updatedAt] : date de dernière mise à jour.
  SeenContentHiveModel({required this.id, required this.createdAt, required this.updatedAt});

  /// Crée un [SeenContentHiveModel] depuis une entité [SeenContent].
  ///
  /// - [entity] : entité à persister.
  factory SeenContentHiveModel.fromEntity(SeenContent entity) {
    return SeenContentHiveModel(id: entity.id, createdAt: entity.createdAt, updatedAt: entity.updatedAt);
  }

  /// Identifiant du contenu.
  @HiveField(0)
  final String id;

  /// Moment où le contenu a été reçu ou supprimé.
  @HiveField(1)
  final DateTime createdAt;

  /// Date de dernière mise à jour.
  @HiveField(2)
  final DateTime updatedAt;

  /// Convertit ce modèle en entité [SeenContent].
  SeenContent toEntity() {
    return SeenContent(id: id, createdAt: createdAt, updatedAt: updatedAt);
  }
}
