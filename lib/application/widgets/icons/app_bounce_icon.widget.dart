import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Icône de rebond : une balle qui tombe, rebondit sur le sol en arcs de plus en plus petits, et reste en l'air.
///
/// Aucune icône du catalogue Material ne représente l'action de rebondir :
/// elle est donc dessinée. Les proportions sont exprimées en fraction de la
/// taille, pour un rendu identique quelle que soit [size].
class AppBounceIcon extends ConsumerWidget {
  /// Crée une [AppBounceIcon].
  ///
  /// - [color] : couleur de l'icône.
  /// - [size] : côté de l'icône, en pixels logiques (défaut 16).
  const AppBounceIcon({super.key, required this.color, this.size = 16});

  /// Couleur de l'icône.
  final Color color;

  /// Côté de l'icône, en pixels logiques.
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomPaint(size: Size.square(size), painter: _BounceIconPainter(color));
  }
}

/// Dessine l'[AppBounceIcon] : sol, trajectoire de la balle, puis la balle.
class _BounceIconPainter extends CustomPainter {
  /// Crée un [_BounceIconPainter].
  ///
  /// - [color] : couleur de l'icône.
  _BounceIconPainter(this.color);

  /// Couleur de l'icône.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.width;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * 0.09
      ..strokeCap = StrokeCap.round;

    // Le sol.
    canvas.drawLine(Offset(side * 0.06, side * 0.92), Offset(side * 0.94, side * 0.92), stroke);

    // La trajectoire, plus discrète que la balle : la chute, puis deux rebonds de plus en plus bas.
    final trajectory = Path()
      ..moveTo(side * 0.08, side * 0.12)
      ..quadraticBezierTo(side * 0.2, side * 0.12, side * 0.3, side * 0.8)
      ..quadraticBezierTo(side * 0.44, side * 0.22, side * 0.58, side * 0.8)
      ..quadraticBezierTo(side * 0.64, side * 0.5, side * 0.7, side * 0.46);
    canvas.drawPath(trajectory, stroke..color = color.withValues(alpha: 0.55));

    // La balle, en l'air après le deuxième rebond.
    canvas.drawCircle(Offset(side * 0.8, side * 0.42), side * 0.13, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BounceIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
