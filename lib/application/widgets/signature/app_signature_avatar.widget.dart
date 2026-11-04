import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/ghost/app_ghost_effect.widget.dart';
import 'package:bedbug/application/widgets/signature/app_bedbug_frames.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Icône d'une signature : son bedbug (kaomoji, emoji, initiales…), animé frame après frame, avec un effet ghost
/// dans sa couleur.
///
/// Reprend le principe du bedbug du splashscreen : une couche principale et
/// une couche ghost colorée qui tremblent de manière désynchronisée.
class AppSignatureAvatar extends ConsumerWidget {
  /// Crée un [AppSignatureAvatar].
  ///
  /// - [avatarFrames] : frames du bedbug, affichées tour à tour. Au moins une.
  /// - [ghostColor] : couleur de l'effet ghost, celle choisie par l'utilisateur.
  /// - [ghostSpeed] : vitesse de l'effet ghost choisie par l'utilisateur (défaut 1).
  /// - [avatarFrameSpeed] : vitesse de l'animation du bedbug choisie par l'utilisateur (défaut 1).
  /// - [fontSize] : taille du texte (défaut 32).
  /// - [isAnimating] : `false` pour figer l'icône, par exemple dans une liste (défaut `true`).
  const AppSignatureAvatar({
    super.key,
    required this.avatarFrames,
    required this.ghostColor,
    this.ghostSpeed = 1,
    this.avatarFrameSpeed = 1,
    this.fontSize = 32,
    this.isAnimating = true,
  });

  /// Frames du bedbug, affichées tour à tour.
  final List<String> avatarFrames;

  /// Couleur de l'effet ghost.
  final Color ghostColor;

  /// Vitesse de l'effet ghost choisie par l'utilisateur (multiplicateur de la vitesse normale).
  final double ghostSpeed;

  /// Vitesse de l'animation du bedbug choisie par l'utilisateur (multiplicateur de la vitesse normale).
  final double avatarFrameSpeed;

  /// Taille du texte.
  final double fontSize;

  /// Indique si l'icône est animée : effet ghost et passage d'une frame à l'autre.
  final bool isAnimating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppGhostEffect(
      isAnimating: isAnimating,
      speed: ghostSpeed,
      // L'amplitude suit la taille du texte : le tremblement garde le même
      // rendu relatif, que l'icône soit affichée en grand ou en petit.
      intensity: fontSize / 32,
      ghostColor: ghostColor,
      child: AppBedbugFrames(
        frames: avatarFrames,
        speed: avatarFrameSpeed,
        isAnimating: isAnimating,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, color: AppColors.onLight),
      ),
    );
  }
}
