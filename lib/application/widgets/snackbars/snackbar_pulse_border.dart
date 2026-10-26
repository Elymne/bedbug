import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Épaisseur de la bordure au repos, en pixels logiques.
const double _kRestWidth = 1;

/// Épaisseur de la bordure au sommet d'une pulsation, en pixels logiques.
const double _kPeakWidth = 3.5;

/// Durée d'une pulsation à l'intensité minimale (la plus lente).
const int _kSlowestPulseMilliseconds = 1600;

/// Durée d'une pulsation à l'intensité maximale (la plus rapide).
const int _kFastestPulseMilliseconds = 600;

/// Opacité de la couleur de la bordure.
const double _kBorderAlpha = 0.8;

/// Bordure d'une snackbar dont l'épaisseur pulse : elle gonfle d'un coup, puis redescend en rebondissant, en boucle.
///
/// Dessinée à l'intérieur du bord de la snackbar : elle en épouse les coins
/// et grossit vers l'intérieur, sans jamais en sortir. [intensity] ne règle
/// que la vitesse des pulsations, comme pour les bedbugs du fond.
class SnackbarPulseBorder extends ConsumerStatefulWidget {
  /// Crée une [SnackbarPulseBorder].
  ///
  /// - [color] : couleur de la bordure.
  /// - [intensity] : vitesse des pulsations, de 0 (lente) à 1 (rapide).
  /// - [borderRadius] : rayon des coins de la snackbar.
  const SnackbarPulseBorder({super.key, required this.color, required this.intensity, required this.borderRadius});

  /// Couleur de la bordure.
  final Color color;

  /// Vitesse des pulsations, de 0 (lente) à 1 (rapide).
  final double intensity;

  /// Rayon des coins de la snackbar.
  final double borderRadius;

  @override
  ConsumerState<SnackbarPulseBorder> createState() => _State();
}

class _State extends ConsumerState<SnackbarPulseBorder> with SingleTickerProviderStateMixin {
  /// Progression d'une pulsation, rejouée en boucle.
  late final AnimationController _controller = AnimationController(
    duration: Duration(
      milliseconds: lerpDouble(
        _kSlowestPulseMilliseconds,
        _kFastestPulseMilliseconds,
        widget.intensity.clamp(0, 1),
      )!.round(),
    ),
    vsync: this,
  )..repeat();

  /// Épaisseur au fil d'une pulsation : montée rapide, puis descente qui rebondit.
  late final Animation<double> _width = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(begin: _kRestWidth, end: _kPeakWidth).chain(CurveTween(curve: Curves.easeOut)),
      weight: 25,
    ),
    TweenSequenceItem(
      tween: Tween<double>(begin: _kPeakWidth, end: _kRestWidth).chain(CurveTween(curve: Curves.bounceOut)),
      weight: 75,
    ),
  ]).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      // Isole le dessin : seule la bordure est redessinée à chaque frame.
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _width,
          builder: (context, _) {
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: widget.color.withValues(alpha: _kBorderAlpha),
                  width: _width.value,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
