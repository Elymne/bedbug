import 'dart:math';

import 'package:bedbug/application/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Widget d'affichage du titre de l'application.
///
/// À l'initialisation, chaque lettre monte depuis le bas en fondu, en cascade.
/// Une fois le reveal terminé, deux tremblements indépendants sont appliqués :
/// un pour le texte principal, un autre pour le ghost. La couleur du texte
/// principal n'est pas modifiée.
class AppTitleText extends ConsumerStatefulWidget {
  /// Crée un [AppTitleText].
  const AppTitleText({super.key, required this.text, this.style});

  /// Texte du titre à afficher.
  final String text;

  /// Style appliqué au texte principal. La couleur n'est pas modifiée.
  final TextStyle? style;

  @override
  ConsumerState<AppTitleText> createState() => _State();
}

class _State extends ConsumerState<AppTitleText> with TickerProviderStateMixin {
  /// Contrôleur du slide bas → haut en cascade, joué une seule fois.
  late final AnimationController _revealController = AnimationController(
    duration: const Duration(milliseconds: 1400),
    vsync: this,
  )..forward();

  /// Contrôleur du tremblement du texte principal.
  late final AnimationController _trembleController = AnimationController(
    duration: const Duration(milliseconds: 1000),
    vsync: this,
  )..repeat(reverse: true);

  /// Contrôleur du tremblement du ghost, plus lent et déphasé.
  late final AnimationController _ghostTrembleController = AnimationController(
    duration: const Duration(milliseconds: 800),
    vsync: this,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _revealController.dispose();
    _trembleController.dispose();
    _ghostTrembleController.dispose();
    super.dispose();
  }

  /// Calcule le facteur normalisé [0.0, 1.0] de la lettre à [index].
  ///
  /// Vaut 0.0 avant que la lettre commence à animer, 1.0 une fois arrivée.
  /// [total] est le nombre total de caractères dans le texte.
  double _letterT(int index, int total) {
    final progress = _revealController.value;
    const staggerWindow = 0.60;
    const slideDuration = 0.45;
    final start = index / total * staggerWindow;
    final end = (start + slideDuration).clamp(0.0, 1.0);
    if (progress < start) return 0.0;
    return ((progress - start) / (end - start)).clamp(0.0, 1.0);
  }

  /// Calcule le décalage vertical de la lettre à [index].
  ///
  /// Part de 40px sous sa position finale et remonte à 0 avec easeOutCubic.
  double _letterSlideY(int index, int total) {
    final eased = Curves.easeOutCubic.transform(_letterT(index, total));
    return 40.0 * (1.0 - eased);
  }

  /// Calcule l'opacité de la lettre à [index].
  double _letterOpacity(int index, int total) {
    return Curves.easeOutCubic.transform(_letterT(index, total));
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    final style = widget.style;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _revealController,
        _trembleController,
        _ghostTrembleController,
      ]),
      builder: (context, _) {
        final trembleOffset = Offset(
          1.5 * sin(_trembleController.value * pi),
          0.6 * sin(_trembleController.value * pi * 1.7),
        );
        final ghostTrembleOffset = Offset(
          2.2 * sin(_ghostTrembleController.value * pi * 1.3),
          1.0 * sin(_ghostTrembleController.value * pi),
        );

        return Stack(
          alignment: Alignment.center,
          children: [
            // Texte ghost en couleur primaire, avec son propre tremblement.
            Transform.translate(
              offset: ghostTrembleOffset + const Offset(3.0, 2.5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < text.length; i++)
                    Opacity(
                      opacity: _letterOpacity(i, text.length),
                      child: Transform.translate(
                        offset: Offset(0, _letterSlideY(i, text.length)),
                        child: Text(
                          text[i],
                          style: (style ?? const TextStyle()).copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Texte principal sans modification de couleur.
            Transform.translate(
              offset: trembleOffset,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < text.length; i++)
                    Opacity(
                      opacity: _letterOpacity(i, text.length),
                      child: Transform.translate(
                        offset: Offset(0, _letterSlideY(i, text.length)),
                        child: Text(text[i], style: style),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
