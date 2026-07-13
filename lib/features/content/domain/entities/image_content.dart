import 'package:bedbug/features/content/domain/entities/content.dart';

/// Contenu de type image, référençant un fichier stocké localement.
///
/// Le fichier est stocké dans le dossier images géré par l'application.
/// Le chemin absolu est reconstruit à l'exécution via `path_provider` —
/// seul le nom de fichier est persisté.
class ImageContent extends Content {
  /// Crée un [ImageContent].
  ///
  /// - [fileName] : nom du fichier image dans le dossier géré par l'app
  ///   (ex. `550e8400-e29b-41d4-a716-446655440000.jpg`).
  /// - [imageWidth] : largeur native de l'image en pixels.
  /// - [imageHeight] : hauteur native de l'image en pixels.
  /// - [title] : titre optionnel accompagnant l'image.
  /// - [body] : description optionnelle accompagnant l'image.
  ImageContent({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.authorId,
    required super.origin,
    required super.broadcastScore,
    required super.survivalScore,
    required super.bounce,
    required super.senderId,
    required super.sizeInBytes,
    super.subId,
    required this.fileName,
    required this.imageWidth,
    required this.imageHeight,
    required this.title,
    this.body,
  });

  /// Nom du fichier image dans le dossier géré par l'application.
  final String fileName;

  /// Largeur native de l'image en pixels.
  final int imageWidth;

  /// Hauteur native de l'image en pixels.
  final int imageHeight;

  /// Titre accompagnant l'image.
  final String title;

  /// Description optionnelle accompagnant l'image.
  final String? body;

  /// Recrée cet [ImageContent] avec ses scores mis à jour, pour permettre au
  /// use case de recalcul de persister la nouvelle valeur sans connaître le
  /// détail des champs propres à ce sous-type.
  @override
  ImageContent copyWithScores({double? broadcastScore, double? survivalScore}) {
    return ImageContent(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      authorId: authorId,
      origin: origin,
      broadcastScore: broadcastScore ?? this.broadcastScore,
      survivalScore: survivalScore ?? this.survivalScore,
      bounce: bounce,
      senderId: senderId,
      sizeInBytes: sizeInBytes,
      subId: subId,
      fileName: fileName,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      title: title,
      body: body,
    );
  }
}
