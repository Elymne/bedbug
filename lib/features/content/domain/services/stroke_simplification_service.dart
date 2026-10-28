import 'dart:math';

import 'package:bedbug/features/content/domain/object_values/drawing_point.dart';
import 'package:bedbug/shared/domain/service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Écart toléré, en points du repère, entre le trait tracé et le trait simplifié.
///
/// Assez faible pour que la différence ne se voie pas une fois le trait lissé.
const double defaultStrokeTolerance = 1.5;

/// Provider du [StrokeSimplificationService].
final strokeSimplificationServiceProvider = Provider<StrokeSimplificationService>((ref) {
  return const StrokeSimplificationService();
});

/// Retire d'un trait les points qui n'en changent pas la forme.
///
/// Le doigt envoie un point à chaque image, même en ligne droite : la
/// plupart sont inutiles. Les retirer allège le dessin à transmettre et
/// laisse plus de place sous les limites de points. Algorithme de
/// Ramer-Douglas-Peucker : un point n'est gardé que s'il s'écarte assez de
/// la droite qui relie ses voisins gardés.
class StrokeSimplificationService extends Service {
  /// Crée un [StrokeSimplificationService].
  const StrokeSimplificationService();

  /// Retourne [points] sans ceux qui s'écartent de moins de [tolerance] du trait simplifié.
  ///
  /// Le premier et le dernier point sont toujours gardés. Les points
  /// identiques qui se suivent sont fusionnés.
  ///
  /// - [points] : points du trait, dans l'ordre du tracé.
  /// - [tolerance] : écart toléré, en points du repère.
  List<DrawingPoint> simplify(List<DrawingPoint> points, {double tolerance = defaultStrokeTolerance}) {
    final distinct = <DrawingPoint>[
      for (var index = 0; index < points.length; index++)
        if (index == 0 || points[index] != points[index - 1]) points[index],
    ];
    if (distinct.length <= 2) {
      return distinct;
    }

    final isKept = List<bool>.filled(distinct.length, false);
    isKept[0] = true;
    isKept[distinct.length - 1] = true;
    // Pile de segments à examiner, plutôt qu'une récursion : un long trait ne fait pas déborder la pile d'appels.
    final segments = <(int, int)>[(0, distinct.length - 1)];
    while (segments.isNotEmpty) {
      final (start, end) = segments.removeLast();
      var farthestIndex = -1;
      var farthestDistance = 0.0;
      for (var index = start + 1; index < end; index++) {
        final distance = _distanceToSegment(distinct[index], distinct[start], distinct[end]);
        if (distance > farthestDistance) {
          farthestDistance = distance;
          farthestIndex = index;
        }
      }
      if (farthestIndex == -1 || farthestDistance <= tolerance) {
        continue;
      }
      isKept[farthestIndex] = true;
      segments
        ..add((start, farthestIndex))
        ..add((farthestIndex, end));
    }

    return [
      for (var index = 0; index < distinct.length; index++)
        if (isKept[index]) distinct[index],
    ];
  }

  /// Retourne la distance entre [point] et le segment [start]-[end].
  ///
  /// - [point] : point mesuré.
  /// - [start] : début du segment.
  /// - [end] : fin du segment.
  double _distanceToSegment(DrawingPoint point, DrawingPoint start, DrawingPoint end) {
    final segmentX = (end.x - start.x).toDouble();
    final segmentY = (end.y - start.y).toDouble();
    final lengthSquared = segmentX * segmentX + segmentY * segmentY;
    final pointX = (point.x - start.x).toDouble();
    final pointY = (point.y - start.y).toDouble();
    if (lengthSquared == 0) {
      return sqrt(pointX * pointX + pointY * pointY);
    }
    final ratio = ((pointX * segmentX + pointY * segmentY) / lengthSquared).clamp(0.0, 1.0);
    return sqrt(pow(pointX - ratio * segmentX, 2) + pow(pointY - ratio * segmentY, 2));
  }
}
