import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/shared/infrastructure/hive_type_ids.dart';
import 'package:hive_ce/hive.dart';

part 'content_hive_model.g.dart';

/// Discriminant identifiant le type concret d'un [Content] stocké.
const _typeTextContent = 'text_content';

/// DTO Hive représentant un [Content] persisté localement.
///
/// Un seul modèle couvre tous les sous-types de [Content] via le champ
/// [type]. Les champs spécifiques à chaque sous-type sont nullable.
@HiveType(typeId: HiveTypeIds.content)
class ContentHiveModel extends HiveObject {
  /// Crée un [ContentHiveModel].
  ContentHiveModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.authorId,
    required this.type,
    this.title,
    this.body,
  });

  /// Crée un [ContentHiveModel] depuis une entité [Content].
  factory ContentHiveModel.fromEntity(Content entity) {
    if (entity is TextContent) {
      return ContentHiveModel(
        id: entity.id,
        createdAt: entity.createdAt.millisecondsSinceEpoch,
        updatedAt: entity.updatedAt.millisecondsSinceEpoch,
        authorId: entity.authorId,
        type: _typeTextContent,
        title: entity.title,
        body: entity.body,
      );
    }
    throw UnimplementedError(
      'ContentHiveModel.fromEntity : type ${entity.runtimeType} non supporté.',
    );
  }

  /// Identifiant unique du contenu.
  @HiveField(0)
  final String id;

  /// Date de création en millisecondes depuis l'époque Unix.
  @HiveField(1)
  final int createdAt;

  /// Date de mise à jour en millisecondes depuis l'époque Unix.
  @HiveField(2)
  final int updatedAt;

  /// Identifiant de l'auteur du contenu.
  @HiveField(3)
  final String authorId;

  /// Discriminant du type concret de contenu.
  @HiveField(4)
  final String type;

  /// Titre du contenu. Renseigné pour [TextContent] uniquement.
  @HiveField(5)
  final String? title;

  /// Corps du contenu. Renseigné pour [TextContent] uniquement.
  @HiveField(6)
  final String? body;

  /// Convertit ce modèle en entité [Content] concrète.
  Content toEntity() {
    if (type == _typeTextContent) {
      return TextContent(
        id: id,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
        authorId: authorId,
        title: title!,
        body: body!,
      );
    }
    throw UnimplementedError(
      'ContentHiveModel.toEntity : type "$type" non supporté.',
    );
  }
}
