import 'package:bedbug/application/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Widget texte avec effet ghost animé : deux couches de texte qui tremblent
/// de manière désynchronisée grâce à des controllers aux durées premières entre elles.
class AppGhostText extends ConsumerStatefulWidget {
  /// Crée un [AppGhostText].
  ///
  /// - [label] : texte affiché.
  /// - [fontSize] : taille de la police.
  /// - [fontWeight] : graisse de la police.
  /// - [isAnimating] : `true` pour lancer l'animation, `false` pour l'arrêter.
  /// - [speed] : multiplicateur de vitesse (défaut 1.0 — plus grand = plus rapide).
  /// - [intensity] : amplitude des décalages en pixels (défaut 1.0).
  const AppGhostText({
    super.key,
    required this.label,
    required this.fontSize,
    required this.fontWeight,
    required this.isAnimating,
    this.speed = 1.0,
    this.intensity = 1.0,
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

  @override
  ConsumerState<AppGhostText> createState() => _State();
}

class _State extends ConsumerState<AppGhostText> with TickerProviderStateMixin {
  /// Retourne une durée ajustée par [AppGhostText.speed].
  Duration _dur(int ms) => Duration(milliseconds: (ms / widget.speed).round());

  /// Oscillation X du ghost (primary).
  late final AnimationController _ghostX = AnimationController(duration: _dur(850), vsync: this);

  /// Oscillation Y du ghost (primary).
  late final AnimationController _ghostY = AnimationController(duration: _dur(1130), vsync: this);

  /// Oscillation X du main (onLight).
  late final AnimationController _mainX = AnimationController(duration: _dur(970), vsync: this);

  /// Oscillation Y du main (onLight).
  late final AnimationController _mainY = AnimationController(duration: _dur(1370), vsync: this);

  @override
  void initState() {
    super.initState();
    if (widget.isAnimating) _startAnimations();
  }

  @override
  void didUpdateWidget(AppGhostText oldWidget) {
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
    _ghostX.dispose();
    _ghostY.dispose();
    _mainX.dispose();
    _mainY.dispose();
    super.dispose();
  }

  /// Démarre tous les controllers en boucle alternée.
  void _startAnimations() {
    _ghostX.repeat(reverse: true);
    _ghostY.repeat(reverse: true);
    _mainX.repeat(reverse: true);
    _mainY.repeat(reverse: true);
  }

  /// Arrête et remet à zéro tous les controllers.
  void _stopAnimations() {
    _ghostX.stop();
    _ghostY.stop();
    _mainX.stop();
    _mainY.stop();
    _ghostX.reset();
    _ghostY.reset();
    _mainX.reset();
    _mainY.reset();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAnimating) {
      return Text(
        widget.label,
        style: TextStyle(fontSize: widget.fontSize, fontWeight: widget.fontWeight, color: AppColors.onLight),
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_ghostX, _ghostY, _mainX, _mainY]),
      builder: (context, _) {
        final ghostOffset = Offset(3.2 * widget.intensity * _ghostX.value, 2.0 * widget.intensity * _ghostY.value);
        final mainOffset = Offset(1.2 * widget.intensity * _mainX.value, 0.7 * widget.intensity * _mainY.value);
        final style = TextStyle(fontSize: widget.fontSize, fontWeight: widget.fontWeight);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Transform.translate(
              offset: ghostOffset,
              child: Text(widget.label, style: style.copyWith(color: AppColors.primary)),
            ),
            Transform.translate(
              offset: mainOffset,
              child: Text(widget.label, style: style.copyWith(color: AppColors.onLight)),
            ),
          ],
        );
      },
    );
  }
}
