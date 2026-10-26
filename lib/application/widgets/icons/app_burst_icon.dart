import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Longueur de chaque pointe de l'explosion, en fraction du côté de l'icône.
///
/// Irrégulières à dessein : des pointes toutes égales donneraient un badge,
/// pas une explosion.
const List<double> _kSpikeRadii = [0.46, 0.38, 0.45, 0.4, 0.46, 0.36, 0.44, 0.41, 0.46, 0.39];

/// Rayon des creux entre deux pointes, en fraction du côté de l'icône.
const double _kValleyRadius = 0.3;

/// Icône de réaction : le contour d'une explosion façon bande dessinée, avec trois points d'exclamation au centre.
///
/// Dessinée plutôt que tirée du catalogue Material, qui n'a pas d'explosion.
/// Les proportions sont exprimées en fraction de la taille, pour un rendu
/// identique quelle que soit [size].
class AppBurstIcon extends ConsumerWidget {
  /// Crée une [AppBurstIcon].
  ///
  /// - [color] : couleur du contour de l'explosion et des points d'exclamation.
  /// - [size] : côté de l'icône, en pixels logiques (défaut 16).
  const AppBurstIcon({super.key, required this.color, this.size = 16});

  /// Couleur de l'explosion.
  final Color color;

  /// Côté de l'icône, en pixels logiques.
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomPaint(size: Size.square(size), painter: _BurstIconPainter(color));
  }
}

/// Dessine l'[AppBurstIcon] : le contour de l'explosion, puis les trois points d'exclamation au centre.
class _BurstIconPainter extends CustomPainter {
  /// Crée un [_BurstIconPainter].
  ///
  /// - [color] : couleur de l'explosion.
  _BurstIconPainter(this.color);

  /// Couleur de l'explosion.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.width;
    final center = Offset(side / 2, side / 2);

    // L'explosion : une étoile dont les pointes, de longueurs inégales, alternent avec des creux.
    final burst = Path();
    for (var point = 0; point < _kSpikeRadii.length * 2; point++) {
      final radius = side * (point.isEven ? _kSpikeRadii[point ~/ 2] : _kValleyRadius);
      final angle = -pi / 2 + point * pi / _kSpikeRadii.length;
      final vertex = center + Offset(cos(angle) * radius, sin(angle) * radius);
      if (point == 0) {
        burst.moveTo(vertex.dx, vertex.dy);
        continue;
      }
      burst.lineTo(vertex.dx, vertex.dy);
    }
    // Les pointes les plus longues restent sous la moitié du côté : le trait,
    // centré sur le contour, ne déborde pas du carré de l'icône.
    canvas.drawPath(
      burst..close(),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = side * 0.07
        ..strokeJoin = StrokeJoin.round,
    );

    // Les trois points d'exclamation : une barre et un point chacun.
    final bar = Paint()
      ..color = color
      ..strokeWidth = side * 0.07
      ..strokeCap = StrokeCap.round;
    final dot = Paint()..color = color;
    for (final markX in [side * 0.39, side * 0.5, side * 0.61]) {
      canvas
        ..drawLine(Offset(markX, side * 0.36), Offset(markX, side * 0.54), bar)
        ..drawCircle(Offset(markX, side * 0.65), side * 0.04, dot);
    }
  }

  @override
  bool shouldRepaint(_BurstIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
