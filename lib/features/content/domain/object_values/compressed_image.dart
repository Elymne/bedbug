import 'dart:typed_data';

import 'package:bedbug/shared/domain/value_object.dart';

/// Image recompressée, prête à être écrite dans le dossier images de l'app.
///
/// Regroupe les octets produits et les informations qui en découlent
/// (dimensions finales, extension du format de sortie), pour que l'appelant
/// n'ait pas à les redéduire lui-même depuis les octets.
class CompressedImage extends ValueObject {
  /// Crée une [CompressedImage].
  ///
  /// - [bytes] : octets encodés de l'image recompressée.
  /// - [width] : largeur finale en pixels, après redimensionnement.
  /// - [height] : hauteur finale en pixels, après redimensionnement.
  /// - [fileExtension] : extension du format de sortie, sans point (ex. `webp`).
  const CompressedImage({required this.bytes, required this.width, required this.height, required this.fileExtension});

  /// Octets encodés de l'image recompressée.
  final Uint8List bytes;

  /// Largeur finale en pixels.
  final int width;

  /// Hauteur finale en pixels.
  final int height;

  /// Extension du format de sortie, sans point.
  final String fileExtension;
}
