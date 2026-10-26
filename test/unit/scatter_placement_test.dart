import 'dart:math';
import 'dart:ui';

import 'package:bedbug/application/widgets/scatter/scatter_placement.dart';
import 'package:flutter_test/flutter_test.dart';

/// Génère [count] tailles variées, comme des réactions avec ou sans bulle.
///
/// - [count] : nombre de tailles à générer.
/// - [seed] : graine du tirage, pour des tailles reproductibles.
List<Size> _sizes(int count, {int seed = 1}) {
  final random = Random(seed);
  return [
    for (var index = 0; index < count; index++) Size(30 + random.nextDouble() * 130, 24 + random.nextDouble() * 50),
  ];
}

/// Rectangles occupés par les éléments de tailles [sizes] une fois placés selon [placement].
List<Rect> _rects(List<Size> sizes, ScatterPlacement placement) {
  return [for (final (index, size) in sizes.indexed) placement.offsets[index] & size];
}

void main() {
  test('ne retourne aucune position et une hauteur nulle sans élément', () {
    final placement = placeScattered(sizes: const [], width: 300, seed: 1, spacing: 12);

    expect(placement.offsets, isEmpty);
    expect(placement.height, 0);
  });

  test('aucun élément ne chevauche un autre, espacement compris, même avec 200 éléments', () {
    for (final count in [2, 20, 200]) {
      final sizes = _sizes(count);
      final rects = _rects(sizes, placeScattered(sizes: sizes, width: 360, seed: count, spacing: 12));

      for (var first = 0; first < rects.length; first++) {
        for (var second = first + 1; second < rects.length; second++) {
          expect(rects[first].inflate(6).overlaps(rects[second].inflate(6)), isFalse, reason: '$count éléments');
        }
      }
    }
  });

  test('tous les éléments restent dans la largeur, et la hauteur les contient tous', () {
    final sizes = _sizes(50);
    final placement = placeScattered(sizes: sizes, width: 300, seed: 7, spacing: 12);

    for (final rect in _rects(sizes, placement)) {
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(300));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(placement.height));
    }
  });

  test('un élément plus large que la zone est calé à gauche au lieu de déborder à droite', () {
    final placement = placeScattered(sizes: const [Size(400, 40)], width: 300, seed: 1, spacing: 12);

    expect(placement.offsets.single.dx, 0);
  });

  test('la même graine donne le même placement', () {
    final sizes = _sizes(30);

    final first = placeScattered(sizes: sizes, width: 320, seed: 42, spacing: 12);
    final second = placeScattered(sizes: sizes, width: 320, seed: 42, spacing: 12);

    expect(second.offsets, first.offsets);
    expect(second.height, first.height);
  });
}
