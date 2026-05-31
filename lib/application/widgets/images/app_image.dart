import 'package:flutter/material.dart';

/// Rayon des coins arrondis par défaut.
const double _defaultBorderRadius = 8;

/// Widget image générique avec bordure, coins arrondis, placeholder et état d'erreur.
///
/// Accepte n'importe quel [ImageProvider] ([NetworkImage], [FileImage], etc.).
/// Affiche un placeholder si [imageProvider] est `null`, pendant le chargement,
/// ou en cas d'erreur.
class AppImage extends StatelessWidget {
  /// Crée un [AppImage].
  ///
  /// - [imageProvider] : source de l'image. `null` affiche directement le placeholder.
  /// - [width] : largeur de la zone image.
  /// - [height] : hauteur de la zone image.
  /// - [borderRadius] : rayon des coins arrondis (défaut : 8).
  const AppImage({
    super.key,
    required this.imageProvider,
    required this.width,
    required this.height,
    this.borderRadius = _defaultBorderRadius,
  });

  /// Source de l'image. `null` affiche le placeholder.
  final ImageProvider? imageProvider;

  /// Largeur de la zone image.
  final double width;

  /// Hauteur de la zone image.
  final double height;

  /// Rayon des coins arrondis.
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageProvider != null ? _buildImage() : _buildPlaceholder(),
      ),
    );
  }

  /// Construit l'image depuis [imageProvider] avec état de chargement et d'erreur.
  Widget _buildImage() {
    return Image(
      image: imageProvider!,
      width: width,
      height: height,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return _buildPlaceholder();
      },
      errorBuilder: (_, _, _) => _buildPlaceholder(),
    );
  }

  /// Construit le placeholder affiché en l'absence d'image ou pendant le chargement.
  Widget _buildPlaceholder() {
    return const ColoredBox(
      color: Color(0xFFF0F0F0),
      child: Center(child: Icon(Icons.image_outlined, color: Color(0xFFBDBDBD))),
    );
  }
}
