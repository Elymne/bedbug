import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/object_values/content_image.dart';

/// Nombre maximal d'images regroupées dans un même [ImageContent].
///
/// Chaque image alourdit le contenu, qui est stocké localement puis transféré
/// de pair à pair : au-delà d'une dizaine, le contenu deviendrait trop lourd à
/// diffuser, même avec des images plus compressées.
const int maxImagesPerContent = 10;

/// Contenu de type image, regroupant une ou plusieurs images stockées localement.
///
/// Les fichiers sont stockés dans le dossier images géré par l'application.
/// Le chemin absolu est reconstruit à l'exécution via `path_provider` —
/// seuls les noms de fichier sont persistés.
class ImageContent extends Content {
  /// Crée un [ImageContent].
  ///
  /// - [images] : images du contenu, dans l'ordre d'affichage (au moins une,
  ///   au plus [maxImagesPerContent]).
  /// - [title] : titre optionnel accompagnant les images.
  /// - [body] : description optionnelle accompagnant les images.
  ImageContent({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.authorId,
    required super.origin,
    required super.broadcastScore,
    required super.survivalScore,
    required super.displayScore,
    required super.bounce,
    required super.senderId,
    required super.sizeInBytes,
    required super.flair,
    super.tags,
    required this.images,
    required this.title,
    this.body,
  });

  /// Images du contenu, dans l'ordre d'affichage.
  final List<ContentImage> images;

  /// Titre accompagnant les images.
  final String title;

  /// Description optionnelle accompagnant les images.
  final String? body;

  /// Recrée cet [ImageContent] avec ses scores mis à jour, pour permettre au
  /// use case de recalcul de persister la nouvelle valeur sans connaître le
  /// détail des champs propres à ce sous-type.
  @override
  ImageContent copyWithScores({double? broadcastScore, double? survivalScore, double? displayScore}) {
    return ImageContent(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      authorId: authorId,
      origin: origin,
      broadcastScore: broadcastScore ?? this.broadcastScore,
      survivalScore: survivalScore ?? this.survivalScore,
      displayScore: displayScore ?? this.displayScore,
      bounce: bounce,
      senderId: senderId,
      sizeInBytes: sizeInBytes,
      flair: flair,
      tags: tags,
      images: images,
      title: title,
      body: body,
    );
  }

  /// Recrée cet [ImageContent] avec un [sizeInBytes] mis à jour, pour
  /// permettre au use case de sauvegarde de persister le poids réel (taille
  /// cumulée des fichiers sur disque) sans connaître le détail des champs
  /// propres à ce sous-type.
  @override
  ImageContent copyWithSizeInBytes(int sizeInBytes) {
    return ImageContent(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      authorId: authorId,
      origin: origin,
      broadcastScore: broadcastScore,
      survivalScore: survivalScore,
      displayScore: displayScore,
      bounce: bounce,
      senderId: senderId,
      sizeInBytes: sizeInBytes,
      flair: flair,
      tags: tags,
      images: images,
      title: title,
      body: body,
    );
  }
}
