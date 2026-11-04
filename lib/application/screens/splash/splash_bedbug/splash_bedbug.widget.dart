import 'dart:math';

import 'package:bedbug/application/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Délai avant le démarrage de l'animation du bedbug.
const _kDelay = Duration(milliseconds: 1400);

/// Texte ASCII du bedbug affiché sur le splashscreen.
const _kText = '( ノ ^o^)ノ';

/// Widget affichant le bedbug animé du splashscreen.
///
/// L'animation démarre après [_kDelay], au moment où l'animation du titre
/// se termine. Le texte fade in et monte depuis le bas, puis un tremblement
/// avec ghost en couleur primaire boucle indéfiniment.
class SplashBedbug extends ConsumerStatefulWidget {
  /// Crée un [SplashBedbug].
  const SplashBedbug({super.key, this.style});

  /// Style appliqué au texte principal.
  final TextStyle? style;

  @override
  ConsumerState<SplashBedbug> createState() => _State();
}

class _State extends ConsumerState<SplashBedbug> with TickerProviderStateMixin {
  /// Contrôleur du fade in + bounce bas → haut, joué une seule fois.
  late final AnimationController _revealController = AnimationController(
    duration: const Duration(milliseconds: 1200),
    vsync: this,
  );

  /// Animation d'opacité du reveal, fade rapide sur le premier tiers.
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _revealController,
    curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
  );

  /// Animation de translation verticale avec rebond (40px → 0px).
  late final Animation<double> _slideY = Tween<double>(
    begin: 40.0,
    end: 0.0,
  ).animate(CurvedAnimation(parent: _revealController, curve: Curves.elasticOut));

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
  void initState() {
    super.initState();
    Future<void>.delayed(_kDelay, () {
      if (!mounted) return;
      _revealController.forward();
    });
  }

  @override
  void dispose() {
    _revealController.dispose();
    _trembleController.dispose();
    _ghostTrembleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style;

    return AnimatedBuilder(
      animation: Listenable.merge([_revealController, _trembleController, _ghostTrembleController]),
      builder: (context, _) {
        final trembleOffset = Offset(
          1.5 * sin(_trembleController.value * pi),
          0.6 * sin(_trembleController.value * pi * 1.7),
        );
        final ghostTrembleOffset = Offset(
          2.2 * sin(_ghostTrembleController.value * pi * 1.3),
          1.0 * sin(_ghostTrembleController.value * pi),
        );

        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _slideY.value),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ghost en couleur primaire avec son propre tremblement.
                Transform.translate(
                  offset: ghostTrembleOffset + const Offset(3.0, 2.5),
                  child: Text(_kText, style: (style ?? const TextStyle()).copyWith(color: AppColors.primary)),
                ),
                // Texte principal.
                Transform.translate(
                  offset: trembleOffset,
                  child: Text(_kText, style: style),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
