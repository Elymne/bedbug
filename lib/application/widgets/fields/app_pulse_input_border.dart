import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// Épaisseur du halo au plus fin de sa pulsation, en pixels logiques.
const double _kMinHaloWidth = 1;

/// Épaisseur du halo au plus large de sa pulsation, en pixels logiques.
const double _kMaxHaloWidth = 4.5;

/// Opacité du halo.
const double _kHaloAlpha = 0.8;

/// Bordure d'un champ actif : la bordure habituelle, doublée d'un halo qui grossit et rétrécit derrière elle.
///
/// Le halo est dessiné par la bordure, et non par un widget posé autour du
/// champ : seule la bordure connaît le rectangle exact de la zone de saisie,
/// sans le message d'erreur ni le compteur qui l'accompagnent. Il s'étend vers
/// l'extérieur et s'interrompt devant le label flottant, pour ne pas passer
/// derrière son texte.
class AppPulseInputBorder extends OutlineInputBorder {
  /// Crée une [AppPulseInputBorder].
  ///
  /// - [pulse] : progression du halo, de 0 (fin) à 1 (large).
  /// - [haloColor] : couleur du halo.
  /// - [borderSide] : trait de la bordure.
  /// - [borderRadius] : arrondi des coins.
  /// - [gapPadding] : marge autour du label flottant.
  const AppPulseInputBorder({
    required this.pulse,
    required this.haloColor,
    super.borderSide,
    super.borderRadius,
    super.gapPadding,
  });

  /// Progression du halo, de 0 (fin) à 1 (large).
  final Animation<double> pulse;

  /// Couleur du halo.
  final Color haloColor;

  @override
  AppPulseInputBorder copyWith({BorderSide? borderSide, BorderRadius? borderRadius, double? gapPadding}) {
    return AppPulseInputBorder(
      pulse: pulse,
      haloColor: haloColor,
      borderSide: borderSide ?? this.borderSide,
      borderRadius: borderRadius ?? this.borderRadius,
      gapPadding: gapPadding ?? this.gapPadding,
    );
  }

  /// Termine la transition de focus sur cette bordure.
  ///
  /// L'interpolation d'[OutlineInputBorder] produit une bordure ordinaire :
  /// sans ce retour de `this` à son terme, le halo ne serait jamais dessiné.
  ///
  /// - [a] : bordure de départ de la transition.
  /// - [t] : avancement de la transition, de 0 à 1.
  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    return t < 1 ? super.lerpFrom(a, t) : this;
  }

  /// Dessine le halo, puis la bordure par-dessus.
  ///
  /// - [canvas] : surface de dessin.
  /// - [rect] : zone de saisie du champ.
  /// - [gapStart] : début de l'encoche du label flottant, `null` s'il n'y en a pas.
  /// - [gapExtent] : largeur du label flottant.
  /// - [gapPercentage] : ouverture de l'encoche, de 0 à 1.
  /// - [textDirection] : sens d'écriture, qui décide du côté où s'ouvre l'encoche.
  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    final haloWidth = lerpDouble(_kMinHaloWidth, _kMaxHaloWidth, pulse.value)!;

    canvas.save();
    if (gapStart != null && gapExtent > 0 && gapPercentage > 0) {
      final extent = lerpDouble(0, gapExtent + gapPadding * 2, gapPercentage)!;
      final start = textDirection == TextDirection.rtl ? gapStart + gapPadding - extent : gapStart - gapPadding;
      final left = rect.left + math.max(0, start);
      canvas.clipRect(
        Rect.fromLTRB(left, rect.top - _kMaxHaloWidth, left + extent, rect.top),
        clipOp: ClipOp.difference,
      );
    }
    canvas.drawRRect(
      borderRadius.toRRect(rect).inflate(haloWidth / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = haloWidth
        ..color = haloColor.withValues(alpha: _kHaloAlpha),
    );
    canvas.restore();

    super.paint(
      canvas,
      rect,
      gapStart: gapStart,
      gapExtent: gapExtent,
      gapPercentage: gapPercentage,
      textDirection: textDirection,
    );
  }
}
