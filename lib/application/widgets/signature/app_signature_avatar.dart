import 'package:bedbug/application/widgets/ghost/app_ghost_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Icône d'un utilisateur : son texte (kaomoji, emoji, initiales…) avec un effet ghost dans sa couleur.
///
/// Reprend le principe du bedbug du splashscreen : une couche principale et
/// une couche ghost colorée qui tremblent de manière désynchronisée.
class AppSignatureAvatar extends ConsumerWidget {
  /// Crée un [AppSignatureAvatar].
  ///
  /// - [avatarText] : texte composant l'icône.
  /// - [ghostColor] : couleur de l'effet ghost, celle choisie par l'utilisateur.
  /// - [ghostSpeed] : vitesse de l'effet ghost choisie par l'utilisateur (défaut 1).
  /// - [fontSize] : taille du texte (défaut 32).
  /// - [isAnimating] : `false` pour figer l'icône, par exemple dans une liste (défaut `true`).
  const AppSignatureAvatar({
    super.key,
    required this.avatarText,
    required this.ghostColor,
    this.ghostSpeed = 1,
    this.fontSize = 32,
    this.isAnimating = true,
  });

  /// Texte composant l'icône.
  final String avatarText;

  /// Couleur de l'effet ghost.
  final Color ghostColor;

  /// Vitesse de l'effet ghost choisie par l'utilisateur (multiplicateur de la vitesse normale).
  final double ghostSpeed;

  /// Taille du texte.
  final double fontSize;

  /// Indique si l'effet ghost est animé.
  final bool isAnimating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppGhostText(
      label: avatarText,
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      isAnimating: isAnimating,
      ghostColor: ghostColor,
      speed: ghostSpeed,
      // L'amplitude suit la taille du texte : le tremblement garde le même
      // rendu relatif, que l'icône soit affichée en grand ou en petit.
      intensity: fontSize / 32,
    );
  }
}
