import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/ghost/app_ghost_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Effet ghost animé appliqué à n'importe quel widget : deux couches qui tremblent de manière désynchronisée.
///
/// La couche du dessous est la silhouette de [child] teintée de
/// [ghostColor], la couche du dessus est [child] tel quel. Composition par
/// défaut d'[AppGhostAnimation], qui sert de base au texte ghost
/// (`AppGhostText`). Pour empiler les couches autrement, utiliser
/// directement [AppGhostAnimation].
class AppGhostEffect extends ConsumerWidget {
  /// Crée un [AppGhostEffect].
  ///
  /// - [child] : widget auquel appliquer l'effet.
  /// - [isAnimating] : `true` pour lancer l'animation, `false` pour afficher [child] seul, figé.
  /// - [speed] : multiplicateur de vitesse (défaut 1.0 — plus grand = plus rapide).
  /// - [intensity] : amplitude des décalages en pixels (défaut 1.0).
  /// - [ghostColor] : couleur de la couche ghost (défaut [AppColors.primary]).
  const AppGhostEffect({
    super.key,
    required this.child,
    required this.isAnimating,
    this.speed = 1.0,
    this.intensity = 1.0,
    this.ghostColor = AppColors.primary,
  });

  /// Widget auquel appliquer l'effet.
  final Widget child;

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
    return AppGhostAnimation(
      isAnimating: isAnimating,
      speed: speed,
      intensity: intensity,
      builder: (context, offsets) {
        if (offsets == null) {
          return child;
        }
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Transform.translate(
              offset: offsets.ghost,
              // `srcIn` ne garde que la forme de l'enfant, remplie de la couleur ghost.
              child: ColorFiltered(colorFilter: ColorFilter.mode(ghostColor, BlendMode.srcIn), child: child),
            ),
            Transform.translate(offset: offsets.main, child: child),
          ],
        );
      },
    );
  }
}
