import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/image_content.dart';
import 'package:bedbug/features/content/domain/entities/link_content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/enums/tag.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/infrastructure/hive_type_ids.dart';
import 'package:hive_ce/hive.dart';

part 'content_hive_model.g.dart';

/// Discriminant identifiant le type concret d'un [Content] stocké.
const _typeTextContent = 'text_content';
const _typeLinkContent = 'link_content';
const _typeImageContent = 'image_content';

/// Flair attribué aux contenus persistés avant que le flair devienne obligatoire.
const _legacyFlair = 'public';

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
    required this.origin,
    required this.broadcastScore,
    required this.survivalScore,
    required this.displayScore,
    required this.bounce,
    required this.senderId,
    this.title,
    this.body,
    this.url,
    this.fileName,
    this.imageWidth,
    this.imageHeight,
    required this.flair,
    required this.sizeInBytes,
    this.ogImageUrl,
    this.ogTitle,
    this.ogDescription,
    this.tagValues = const [],
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
        origin: entity.origin.value,
        broadcastScore: entity.broadcastScore,
        survivalScore: entity.survivalScore,
        displayScore: entity.displayScore,
        bounce: entity.bounce,
        senderId: entity.senderId,
        title: entity.title,
        body: entity.body,
        flair: entity.flair,
        sizeInBytes: entity.sizeInBytes,
        tagValues: entity.tags.map((tag) => tag.value).toList(),
      );
    }
    if (entity is LinkContent) {
      return ContentHiveModel(
        id: entity.id,
        createdAt: entity.createdAt.millisecondsSinceEpoch,
        updatedAt: entity.updatedAt.millisecondsSinceEpoch,
        authorId: entity.authorId,
        type: _typeLinkContent,
        origin: entity.origin.value,
        broadcastScore: entity.broadcastScore,
        survivalScore: entity.survivalScore,
        displayScore: entity.displayScore,
        bounce: entity.bounce,
        senderId: entity.senderId,
        title: entity.title,
        body: entity.body,
        url: entity.url,
        flair: entity.flair,
        sizeInBytes: entity.sizeInBytes,
        ogImageUrl: entity.ogImageUrl,
        ogTitle: entity.ogTitle,
        ogDescription: entity.ogDescription,
        tagValues: entity.tags.map((tag) => tag.value).toList(),
      );
    }
    if (entity is ImageContent) {
      return ContentHiveModel(
        id: entity.id,
        createdAt: entity.createdAt.millisecondsSinceEpoch,
        updatedAt: entity.updatedAt.millisecondsSinceEpoch,
        authorId: entity.authorId,
        type: _typeImageContent,
        origin: entity.origin.value,
        broadcastScore: entity.broadcastScore,
        survivalScore: entity.survivalScore,
        displayScore: entity.displayScore,
        bounce: entity.bounce,
        senderId: entity.senderId,
        fileName: entity.fileName,
        imageWidth: entity.imageWidth,
        imageHeight: entity.imageHeight,
        title: entity.title,
        body: entity.body,
        flair: entity.flair,
        sizeInBytes: entity.sizeInBytes,
        tagValues: entity.tags.map((tag) => tag.value).toList(),
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

  /// Provenance du contenu encodée comme valeur de [ContentOrigin].
  @HiveField(7)
  final int origin;

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

  /// Flair libre du contenu, sans le `/` initial.
  ///
  /// Le champ 12 (ancien `subId`) est volontairement laissé inutilisé : le
  /// réutiliser ferait relire les anciens identifiants de sub comme des flairs.
  /// Les contenus persistés avant l'ajout du flair n'ont pas ce champ : ils
  /// sont relus avec [_legacyFlair] au lieu de faire échouer la lecture.
  @HiveField(23, defaultValue: _legacyFlair)
  final String flair;

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

  /// Score de probabilité de diffusion prioritaire en BLE/WIFI.
  @HiveField(19)
  final double broadcastScore;

  /// Score de probabilité de conservation lors d'un nettoyage automatique.
  @HiveField(20)
  final double survivalScore;

  /// Score de priorité d'affichage dans la liste de la page d'accueil.
  @HiveField(21)
  final double displayScore;

  /// Valeurs [Tag.value] des tags associés à ce contenu.
  @HiveField(22)
  final List<int> tagValues;

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
    final tags = tagValues.map((value) => Tag.values.firstWhere((tag) => tag.value == value)).toList();
    if (type == _typeTextContent) {
      return TextContent(
        id: id,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
        authorId: authorId,
        origin: ContentOrigin.values.firstWhere((value) => value.value == origin),
        broadcastScore: broadcastScore,
        survivalScore: survivalScore,
        displayScore: displayScore,
        bounce: bounce,
        senderId: senderId,
        title: title!,
        body: body!,
        flair: flair,
        sizeInBytes: sizeInBytes,
        tags: tags,
      );
    }
    if (type == _typeLinkContent) {
      return LinkContent(
        id: id,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
        authorId: authorId,
        origin: ContentOrigin.values.firstWhere((value) => value.value == origin),
        broadcastScore: broadcastScore,
        survivalScore: survivalScore,
        displayScore: displayScore,
        bounce: bounce,
        senderId: senderId,
        title: title ?? url!,
        body: body,
        url: url!,
        flair: flair,
        sizeInBytes: sizeInBytes,
        ogImageUrl: ogImageUrl,
        ogTitle: ogTitle,
        ogDescription: ogDescription,
        tags: tags,
      );
    }
    if (type == _typeImageContent) {
      return ImageContent(
        id: id,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
        authorId: authorId,
        origin: ContentOrigin.values.firstWhere((value) => value.value == origin),
        broadcastScore: broadcastScore,
        survivalScore: survivalScore,
        displayScore: displayScore,
        bounce: bounce,
        senderId: senderId,
        fileName: fileName!,
        imageWidth: imageWidth!,
        imageHeight: imageHeight!,
        title: title!,
        body: body,
        flair: flair,
        sizeInBytes: sizeInBytes,
        tags: tags,
      );
    }
    throw UnimplementedError('ContentHiveModel._toEntity : type "$type" non supporté.');
  }
}
