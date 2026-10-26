import 'dart:ui';

import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/ghost/app_ghost_animation.dart';
import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Largeur réservée à chaque bedbug de la rangée, en pixels logiques.
const double _kBedbugSlotWidth = 96;

/// Amplitude du tremblement, fixe : un décalage plus grand rend le fond brouillon.
const double _kGhostAmplitude = 1;

/// Opacité du ghost des bedbugs, fixe.
const double _kGhostAlpha = 0.6;

/// Fond animé d'une snackbar : une rangée de bedbugs discrets qui tremblent avec un effet ghost coloré.
///
/// Les bedbugs restent en retrait (texte presque transparent) pour ne pas
/// gêner la lecture du message ; c'est leur ghost coloré qui porte le ton de
/// la snackbar. [intensity] ne règle que la vitesse du tremblement, dont
/// l'amplitude reste douce : lent pour une confirmation, frénétique pour une
/// erreur qu'on ne doit pas rater.
class SnackbarBedbugBackground extends ConsumerWidget {
  /// Crée un [SnackbarBedbugBackground].
  ///
  /// - [bedbug] : kaomoji répété sur toute la largeur.
  /// - [ghostColor] : couleur du ghost des bedbugs.
  /// - [intensity] : vitesse de l'animation, de 0 (lente) à 1 (frénétique).
  const SnackbarBedbugBackground({super.key, required this.bedbug, required this.ghostColor, required this.intensity});

  /// Kaomoji répété sur toute la largeur.
  final String bedbug;

  /// Couleur du ghost des bedbugs.
  final Color ghostColor;

  /// Vitesse de l'animation, de 0 (lente) à 1 (frénétique).
  final double intensity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speed = lerpDouble(minGhostSpeed, maxGhostSpeed, intensity.clamp(0, 1))!;

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bedbugCount = (constraints.maxWidth / _kBedbugSlotWidth).floor().clamp(1, 12);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var index = 0; index < bedbugCount; index++)
                AppGhostAnimation(
                  isAnimating: true,
                  speed: speed,
                  intensity: _kGhostAmplitude,
                  builder: (context, offsets) {
                    // Deux textes distincts plutôt que la silhouette d'un seul : le
                    // bedbug reste discret, mais son ghost garde toute sa couleur.
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Transform.translate(
                          offset: offsets?.ghost ?? Offset.zero,
                          child: Text(bedbug, maxLines: 1, style: _style(ghostColor.withValues(alpha: _kGhostAlpha))),
                        ),
                        Transform.translate(
                          offset: offsets?.main ?? Offset.zero,
                          child: Text(bedbug, maxLines: 1, style: _style(AppColors.onDark.withValues(alpha: 0.12))),
                        ),
                      ],
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  /// Style d'un bedbug de la rangée, dans la couleur [color].
  ///
  /// - [color] : couleur du texte.
  TextStyle _style(Color color) {
    return TextStyle(fontSize: 13, color: color);
  }
}
