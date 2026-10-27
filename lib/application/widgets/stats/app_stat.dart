import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/ghost/app_ghost_effect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Vitesse de l'effet ghost d'une statistique, plus lente que la normale.
///
/// Les statistiques sont répétées sur chaque tuile du fil : un tremblement
/// discret les anime sans attirer l'œil plus que le contenu lui-même.
const double _kStatGhostSpeed = 0.5;

/// Amplitude de l'effet ghost d'une statistique, en pixels, réduite pour rester lisible à petite taille.
const double _kStatGhostIntensity = 0.5;

/// Statistique compacte : une icône suivie d'un nombre, tremblant ensemble d'un léger effet ghost.
///
/// Remplace un tag quand seul un chiffre compte (rebonds, réactions) : plus
/// léger visuellement, il laisse la place aux vrais tags du contenu. L'icône
/// et le nombre gardent la couleur du texte, plus lisible qu'une couleur vive
/// sur fond clair ; c'est la couleur de leur effet ghost, [ghostColor], qui
/// distingue une statistique d'une autre. [semanticsLabel] est lu par les
/// lecteurs d'écran à la place de l'icône et du nombre, qui seuls ne veulent
/// rien dire.
class AppStat extends ConsumerWidget {
  /// Crée une [AppStat].
  ///
  /// - [icon] : icône de la statistique, dessinée en [AppColors.onLight].
  /// - [label] : nombre affiché (ex. `+12`).
  /// - [ghostColor] : couleur de l'effet ghost de l'icône et du nombre.
  /// - [semanticsLabel] : libellé complet lu par les lecteurs d'écran (ex. « 12 rebonds »).
  const AppStat({
    super.key,
    required this.icon,
    required this.label,
    required this.ghostColor,
    required this.semanticsLabel,
  });

  /// Icône de la statistique.
  final Widget icon;

  /// Nombre affiché.
  final String label;

  /// Couleur de l'effet ghost de l'icône et du nombre.
  final Color ghostColor;

  /// Libellé complet lu par les lecteurs d'écran.
  final String semanticsLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: AppGhostEffect(
        isAnimating: true,
        speed: _kStatGhostSpeed,
        intensity: _kStatGhostIntensity,
        ghostColor: ghostColor,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            icon,
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onLight),
            ),
          ],
        ),
      ),
    );
  }
}
