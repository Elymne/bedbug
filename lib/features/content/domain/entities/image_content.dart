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
    required super.priority,
    required super.bounce,
    required super.senderId,
    required super.sizeInBytes,
    super.subId,
    required this.fileName,
    required this.imageWidth,
    required this.imageHeight,
    this.title,
    this.body,
  });

  /// Nom du fichier image dans le dossier géré par l'application.
  final String fileName;

  /// Largeur native de l'image en pixels.
  final int imageWidth;

  /// Hauteur native de l'image en pixels.
  final int imageHeight;

  /// Titre optionnel accompagnant l'image.
  final String? title;

  /// Description optionnelle accompagnant l'image.
  final String? body;
}
