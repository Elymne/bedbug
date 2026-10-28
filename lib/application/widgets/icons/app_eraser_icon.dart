import 'dart:math';

import 'package:bedbug/application/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Icône de gomme : un bloc incliné, sa pointe pleine et le reste en contour, posé sur le trait qu'il efface.
///
/// Le catalogue Material n'a pas de gomme, et la baguette magique qui la
/// remplaçait ne se reconnaissait pas : elle est donc dessinée. Les
/// proportions sont exprimées en fraction de la taille, pour un rendu
/// identique quelle que soit [size].
class AppEraserIcon extends ConsumerWidget {
  /// Crée une [AppEraserIcon].
  ///
  /// - [color] : couleur de l'icône, `null` pour celle du thème d'icônes (celle que donne un `IconButton`).
  /// - [size] : côté de l'icône, en pixels logiques (défaut 24, comme une icône Material).
  const AppEraserIcon({super.key, this.color, this.size = 24});

  /// Couleur de l'icône, `null` pour celle du thème d'icônes.
  final Color? color;

  /// Côté de l'icône, en pixels logiques.
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconColor = color ?? IconTheme.of(context).color ?? AppColors.onLight;
    return CustomPaint(size: Size.square(size), painter: _EraserIconPainter(iconColor));
  }
}

/// Dessine l'[AppEraserIcon] : le corps de la gomme en contour, sa pointe pleine, puis la trace au sol.
class _EraserIconPainter extends CustomPainter {
  /// Crée un [_EraserIconPainter].
  ///
  /// - [color] : couleur de l'icône.
  _EraserIconPainter(this.color);

  /// Couleur de l'icône.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.width;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * 0.08
      ..strokeJoin = StrokeJoin.round;

    // La trace au sol, à droite de la pointe : ce qui reste de l'effacement.
    canvas.drawLine(
      Offset(side * 0.5, side * 0.88),
      Offset(side * 0.92, side * 0.88),
      Paint()
        ..color = color.withValues(alpha: 0.55)
        ..strokeWidth = side * 0.08
        ..strokeCap = StrokeCap.round,
    );

    // Le bloc, incliné à 45°, la pointe en bas à gauche.
    canvas
      ..save()
      ..translate(side * 0.52, side * 0.46)
      ..rotate(-pi / 4);
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: side * 0.78, height: side * 0.42),
      Radius.circular(side * 0.08),
    );
    // La pointe, pleine : le tiers gauche du bloc, celui qui frotte le papier.
    canvas
      ..save()
      ..clipRect(Rect.fromLTRB(body.left, body.top, body.left + body.width * 0.36, body.bottom))
      ..drawRRect(body, Paint()..color = color)
      ..restore()
      ..drawRRect(body, stroke)
      ..restore();
  }

  @override
  bool shouldRepaint(_EraserIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
