import 'dart:io';

import 'package:bedbug/application/widgets/images/app_image.dart';
import 'package:flutter/material.dart';

/// Image depuis le stockage local du device avec bordure, coins arrondis,
/// placeholder et état d'erreur.
///
/// Délègue le rendu à [AppImage] en passant un [FileImage].
class AppFileImage extends StatelessWidget {
  /// Crée un [AppFileImage].
  ///
  /// - [file] : fichier image local. `null` affiche le placeholder.
  /// - [width] : largeur de la zone image.
  /// - [height] : hauteur de la zone image.
  /// - [borderRadius] : rayon des coins arrondis (défaut : 8).
  /// - [fit] : façon d'adapter l'image à la zone (défaut : [BoxFit.cover], qui la recadre).
  const AppFileImage({
    super.key,
    required this.file,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.fit = BoxFit.cover,
  });

  /// Fichier image local. `null` affiche le placeholder.
  final File? file;

  /// Largeur de la zone image.
  final double width;

  /// Hauteur de la zone image.
  final double height;

  /// Rayon des coins arrondis.
  final double borderRadius;

  /// Façon d'adapter l'image à la zone : [BoxFit.contain] pour la voir en entier.
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return AppImage(
      imageProvider: file != null ? FileImage(file!) : null,
      width: width,
      height: height,
      borderRadius: borderRadius,
      fit: fit,
    );
  }
}
