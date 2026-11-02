import 'package:bedbug/resources/content/viewed_content/viewed_content.entity.dart';
import 'package:bedbug/resources/hive.type_ids.dart';
import 'package:hive_ce/hive.dart';

part 'viewed_content.model.hive.g.dart';

/// DTO Hive représentant un [ViewedContent] persisté localement.
@HiveType(typeId: HiveTypeIds.viewedContent)
class ViewedContentHiveModel extends HiveObject {
  /// Crée un [ViewedContentHiveModel].
  ///
  /// - [id] : identifiant du contenu vu.
  /// - [createdAt] : moment où le contenu a été vu.
  /// - [updatedAt] : date de dernière mise à jour.
  ViewedContentHiveModel({required this.id, required this.createdAt, required this.updatedAt});

  /// Crée un [ViewedContentHiveModel] depuis une entité [ViewedContent].
  ///
  /// - [entity] : entité à persister.
  factory ViewedContentHiveModel.fromEntity(ViewedContent entity) {
    return ViewedContentHiveModel(id: entity.id, createdAt: entity.createdAt, updatedAt: entity.updatedAt);
  }

  /// Identifiant du contenu vu.
  @HiveField(0)
  final String id;

  /// Moment où le contenu a été vu.
  @HiveField(1)
  final DateTime createdAt;

  /// Date de dernière mise à jour.
  @HiveField(2)
  final DateTime updatedAt;

  /// Convertit ce modèle en entité [ViewedContent].
  ViewedContent toEntity() {
    return ViewedContent(id: id, createdAt: createdAt, updatedAt: updatedAt);
  }
}
