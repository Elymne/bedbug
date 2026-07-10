import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/image_content.dart';
import 'package:bedbug/features/content/domain/entities/link_content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_priority.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/infrastructure/hive_type_ids.dart';
import 'package:hive_ce/hive.dart';

part 'content_hive_model.g.dart';

/// Discriminant identifiant le type concret d'un [Content] stocké.
const _typeTextContent = 'text_content';
const _typeLinkContent = 'link_content';
const _typeImageContent = 'image_content';

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
    required this.priority,
    required this.bounce,
    required this.senderId,
    this.title,
    this.body,
    this.url,
    this.fileName,
    this.imageWidth,
    this.imageHeight,
    this.subId,
    required this.sizeInBytes,
    this.ogImageUrl,
    this.ogTitle,
    this.ogDescription,
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
        priority: entity.priority.value,
        bounce: entity.bounce,
        senderId: entity.senderId,
        title: entity.title,
        body: entity.body,
        subId: entity.subId,
        sizeInBytes: entity.sizeInBytes,
      );
    }
    if (entity is LinkContent) {
      return ContentHiveModel(
        id: entity.id,
        createdAt: entity.createdAt.millisecondsSinceEpoch,
        updatedAt: entity.updatedAt.millisecondsSinceEpoch,
        authorId: entity.authorId,
        type: _typeLinkContent,
        priority: entity.priority.value,
        bounce: entity.bounce,
        senderId: entity.senderId,
        title: entity.title,
        body: entity.body,
        url: entity.url,
        subId: entity.subId,
        sizeInBytes: entity.sizeInBytes,
        ogImageUrl: entity.ogImageUrl,
        ogTitle: entity.ogTitle,
        ogDescription: entity.ogDescription,
      );
    }
    if (entity is ImageContent) {
      return ContentHiveModel(
        id: entity.id,
        createdAt: entity.createdAt.millisecondsSinceEpoch,
        updatedAt: entity.updatedAt.millisecondsSinceEpoch,
        authorId: entity.authorId,
        type: _typeImageContent,
        priority: entity.priority.value,
        bounce: entity.bounce,
        senderId: entity.senderId,
        fileName: entity.fileName,
        imageWidth: entity.imageWidth,
        imageHeight: entity.imageHeight,
        title: entity.title,
        body: entity.body,
        subId: entity.subId,
        sizeInBytes: entity.sizeInBytes,
      );
    }
    throw UnimplementedError('ContentHiveModel.fromEntity : type ${entity.runtimeType} non supporté.');
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

  /// Priorité du contenu encodée comme valeur de [ContentPriority].
  @HiveField(7)
  final int priority;

  /// Nombre de rebonds du contenu entre appareils.
  @HiveField(8)
  final int bounce;

  /// Identifiant de l'appareil ou de l'utilisateur ayant transmis ce contenu.
  @HiveField(9)
  final String senderId;

  /// URL du lien. Renseigné pour [LinkContent] uniquement.
  @HiveField(10)
  final String? url;

  /// Nom du fichier image dans le dossier géré par l'app.
  /// Renseigné pour [ImageContent] uniquement.
  @HiveField(11)
  final String? fileName;

  /// Largeur native de l'image en pixels. Renseigné pour [ImageContent] uniquement.
  @HiveField(17)
  final int? imageWidth;

  /// Hauteur native de l'image en pixels. Renseigné pour [ImageContent] uniquement.
  @HiveField(18)
  final int? imageHeight;

  /// Identifiant du sub auquel appartient ce contenu.
  /// `null` si le contenu est purement public.
  @HiveField(12)
  final String? subId;

  /// Poids du contenu en octets.
  @HiveField(13)
  final int sizeInBytes;

  /// URL de l'image Open Graph. Renseigné pour [LinkContent] uniquement.
  @HiveField(14)
  final String? ogImageUrl;

  /// Titre Open Graph. Renseigné pour [LinkContent] uniquement.
  @HiveField(15)
  final String? ogTitle;

  /// Description Open Graph. Renseignée pour [LinkContent] uniquement.
  @HiveField(16)
  final String? ogDescription;

  /// Convertit ce modèle en entité [Content] concrète.
  Content toEntity() {
    try {
      return _toEntity();
    } catch (error) {
      if (error is DataException) rethrow;
      throw DataException('ContentHiveModel', error);
    }
  }

  Content _toEntity() {
    if (type == _typeTextContent) {
      return TextContent(
        id: id,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
        authorId: authorId,
        priority: ContentPriority.values.firstWhere((p) => p.value == priority),
        bounce: bounce,
        senderId: senderId,
        title: title!,
        body: body!,
        subId: subId,
        sizeInBytes: sizeInBytes,
      );
    }
    if (type == _typeLinkContent) {
      return LinkContent(
        id: id,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
        authorId: authorId,
        priority: ContentPriority.values.firstWhere((p) => p.value == priority),
        bounce: bounce,
        senderId: senderId,
        title: title ?? url!,
        body: body,
        url: url!,
        subId: subId,
        sizeInBytes: sizeInBytes,
        ogImageUrl: ogImageUrl,
        ogTitle: ogTitle,
        ogDescription: ogDescription,
      );
    }
    if (type == _typeImageContent) {
      return ImageContent(
        id: id,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
        authorId: authorId,
        priority: ContentPriority.values.firstWhere((p) => p.value == priority),
        bounce: bounce,
        senderId: senderId,
        fileName: fileName!,
        imageWidth: imageWidth!,
        imageHeight: imageHeight!,
        title: title!,
        body: body,
        subId: subId,
        sizeInBytes: sizeInBytes,
      );
    }
    throw UnimplementedError('ContentHiveModel._toEntity : type "$type" non supporté.');
  }
}
