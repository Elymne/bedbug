import 'package:bedbug/shared/domain/value_object.dart';

/// Une image d'un `ImageContent`, référençant un fichier stocké localement.
///
/// Un contenu image peut regrouper plusieurs images : chacune garde son propre
/// fichier et ses propres dimensions, nécessaires pour réserver la bonne
/// hauteur d'affichage avant que le fichier ne soit décodé.
class ContentImage extends ValueObject {
  /// Crée une [ContentImage].
  ///
  /// - [fileName] : nom du fichier image dans le dossier géré par l'app
  ///   (ex. `550e8400-e29b-41d4-a716-446655440000.webp`).
  /// - [width] : largeur de l'image en pixels.
  /// - [height] : hauteur de l'image en pixels.
  const ContentImage({required this.fileName, required this.width, required this.height});

  /// Nom du fichier image dans le dossier géré par l'application.
  final String fileName;

  /// Largeur de l'image en pixels.
  final int width;

  /// Hauteur de l'image en pixels.
  final int height;

  @override
  bool operator ==(Object other) {
    return other is ContentImage && other.fileName == fileName && other.width == width && other.height == height;
  }

  @override
  int get hashCode {
    return Object.hash(fileName, width, height);
  }
}
