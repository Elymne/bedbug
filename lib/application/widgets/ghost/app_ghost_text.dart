import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/ghost/app_ghost_effect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Widget texte avec effet ghost animé : deux couches de texte qui tremblent de manière désynchronisée.
///
/// Raccourci d'[AppGhostEffect] pour un simple texte : la couche principale
/// est écrite en [AppColors.onLight], la couche ghost en [ghostColor].
class AppGhostText extends ConsumerWidget {
  /// Crée un [AppGhostText].
  ///
  /// - [label] : texte affiché.
  /// - [fontSize] : taille de la police.
  /// - [fontWeight] : graisse de la police.
  /// - [isAnimating] : `true` pour lancer l'animation, `false` pour l'arrêter.
  /// - [speed] : multiplicateur de vitesse (défaut 1.0 — plus grand = plus rapide).
  /// - [intensity] : amplitude des décalages en pixels (défaut 1.0).
  /// - [ghostColor] : couleur de la couche ghost (défaut [AppColors.primary]).
  const AppGhostText({
    super.key,
    required this.label,
    required this.fontSize,
    required this.fontWeight,
    required this.isAnimating,
    this.speed = 1.0,
    this.intensity = 1.0,
    this.ghostColor = AppColors.primary,
  });

  /// Texte affiché.
  final String label;

  /// Taille de la police.
  final double fontSize;

  /// Graisse de la police.
  final FontWeight fontWeight;

  /// Indique si l'animation est active.
  final bool isAnimating;

  /// Multiplicateur de vitesse des controllers.
  final double speed;

  /// Amplitude des décalages en pixels.
  final double intensity;

  /// Couleur de la couche ghost.
  final Color ghostColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppGhostEffect(
      isAnimating: isAnimating,
      speed: speed,
      intensity: intensity,
      ghostColor: ghostColor,
      child: Text(
        label,
        style: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: AppColors.onLight),
      ),
    );
  }
}
