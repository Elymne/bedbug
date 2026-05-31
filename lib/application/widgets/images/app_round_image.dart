import 'dart:io';

import 'package:flutter/material.dart';

/// Taille par défaut du widget image ronde.
const double _defaultSize = 20;

/// Image ronde depuis le stockage local du device avec placeholder.
///
/// Affiche une icône personne si [file] est `null` ou en cas d'erreur.
class AppRoundImage extends StatelessWidget {
  /// Crée un [AppRoundImage].
  ///
  /// - [file] : fichier image local. `null` affiche le placeholder.
  /// - [size] : diamètre du cercle (défaut : 32).
  const AppRoundImage({super.key, required this.file, this.size = _defaultSize});

  /// Fichier image local. `null` affiche le placeholder.
  final File? file;

  /// Diamètre du cercle.
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(width: size, height: size, child: file != null ? _buildImage() : _buildPlaceholder()),
    );
  }

  /// Construit l'image depuis [file] avec état d'erreur.
  Widget _buildImage() {
    return Image(
      image: FileImage(file!),
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _buildPlaceholder(),
    );
  }

  /// Construit le placeholder affiché en l'absence d'image.
  Widget _buildPlaceholder() {
    return const ColoredBox(
      color: Color(0xFFE0E0E0),
      child: Center(child: Icon(Icons.public, color: Color(0xFF9E9E9E))),
    );
  }
}
