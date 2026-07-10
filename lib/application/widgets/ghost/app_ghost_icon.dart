import 'package:bedbug/application/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Widget icône avec effet ghost animé : deux couches qui pulsent (scale) de manière
/// désynchronisée grâce à des controllers aux durées premières entre elles.
class AppGhostIcon extends ConsumerStatefulWidget {
  /// Crée un [AppGhostIcon].
  ///
  /// - [icon] : icône affichée.
  /// - [size] : taille de l'icône.
  /// - [isAnimating] : `true` pour lancer l'animation, `false` pour l'arrêter.
  /// - [speed] : multiplicateur de vitesse (défaut 1.0 — plus grand = plus rapide).
  /// - [intensity] : amplitude du scale (défaut 1.0 — représente ~15 % de variation max).
  const AppGhostIcon({
    super.key,
    required this.icon,
    required this.size,
    required this.isAnimating,
    this.speed = 1.0,
    this.intensity = 1.0,
  });

  /// Icône affichée.
  final IconData icon;

  /// Taille de l'icône.
  final double size;

  /// Indique si l'animation est active.
  final bool isAnimating;

  /// Multiplicateur de vitesse des controllers.
  final double speed;

  /// Amplitude du scale (1.0 = ±15 % pour le ghost, ±8 % pour le main).
  final double intensity;

  @override
  ConsumerState<AppGhostIcon> createState() => _State();
}

class _State extends ConsumerState<AppGhostIcon> with TickerProviderStateMixin {
  /// Retourne une durée ajustée par [AppGhostIcon.speed].
  Duration _dur(int ms) => Duration(milliseconds: (ms / widget.speed).round());

  /// Pulse du ghost (primary) — plus lent, amplitude plus grande.
  late final AnimationController _ghostScale = AnimationController(duration: _dur(900), vsync: this);

  /// Pulse du main (onLight) — plus rapide, amplitude plus douce.
  late final AnimationController _mainScale = AnimationController(duration: _dur(1270), vsync: this);

  @override
  void initState() {
    super.initState();
    if (widget.isAnimating) _startAnimations();
  }

  @override
  void didUpdateWidget(AppGhostIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !oldWidget.isAnimating) {
      _startAnimations();
      return;
    }
    if (!widget.isAnimating && oldWidget.isAnimating) {
      _stopAnimations();
    }
  }

  @override
  void dispose() {
    _ghostScale.dispose();
    _mainScale.dispose();
    super.dispose();
  }

  /// Démarre les controllers en boucle alternée.
  void _startAnimations() {
    _ghostScale.repeat(reverse: true);
    _mainScale.repeat(reverse: true);
  }

  /// Arrête et remet à zéro les controllers.
  void _stopAnimations() {
    _ghostScale.stop();
    _mainScale.stop();
    _ghostScale.reset();
    _mainScale.reset();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAnimating) {
      return Icon(widget.icon, color: AppColors.onLight, size: widget.size);
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_ghostScale, _mainScale]),
      builder: (context, _) {
        final ghostFactor = 1.0 + 0.15 * widget.intensity * _ghostScale.value;
        final mainFactor = 1.0 + 0.08 * widget.intensity * _mainScale.value;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Transform.scale(
                scale: ghostFactor,
                child: Icon(widget.icon, color: AppColors.primary, size: widget.size),
              ),
              Transform.scale(
                scale: mainFactor,
                child: Icon(widget.icon, color: AppColors.onLight, size: widget.size),
              ),
            ],
          ),
        );
      },
    );
  }
}
