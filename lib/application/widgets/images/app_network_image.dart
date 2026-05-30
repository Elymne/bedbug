import 'package:bedbug/application/widgets/images/app_image.dart';
import 'package:flutter/material.dart';

/// Image réseau avec bordure, coins arrondis, placeholder et état d'erreur.
///
/// Délègue le rendu à [AppImage] en passant un [NetworkImage].
class AppNetworkImage extends StatelessWidget {
  /// Crée un [AppNetworkImage].
  ///
  /// - [url] : URL de l'image. `null` affiche le placeholder.
  /// - [width] : largeur de la zone image.
  /// - [height] : hauteur de la zone image.
  /// - [borderRadius] : rayon des coins arrondis (défaut : 8).
  const AppNetworkImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  /// URL de l'image réseau. `null` affiche le placeholder.
  final String? url;

  /// Largeur de la zone image.
  final double width;

  /// Hauteur de la zone image.
  final double height;

  /// Rayon des coins arrondis.
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return AppImage(
      imageProvider: url != null ? NetworkImage(url!) : null,
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}
