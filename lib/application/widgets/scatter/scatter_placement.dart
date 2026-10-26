import 'dart:math';
import 'dart:ui';

/// Rapport entre la surface de la zone de placement et la surface cumulée des éléments.
///
/// À 1, les éléments devraient remplir la zone sans un pixel de vide :
/// introuvable par tirage aléatoire. 1,6 laisse assez de place pour qu'un
/// tirage tombe vite sur un emplacement libre, sans étirer la zone au point
/// que les éléments paraissent perdus.
const double _kLooseness = 1.6;

/// Nombre de tirages ratés avant d'agrandir la zone de placement.
const int _kAttemptsBeforeGrowth = 30;

/// Facteur d'agrandissement de la hauteur de la zone après une série de tirages ratés.
const double _kGrowthFactor = 1.1;

/// Nombre total de tirages par élément avant de le poser sous tous les autres.
///
/// Filet de sécurité : garantit que le placement se termine toujours, même
/// pour un élément qu'aucun tirage n'arrive à caser.
const int _kMaxAttempts = 300;

/// Résultat d'un placement dispersé : la position de chaque élément et la hauteur totale occupée.
class ScatterPlacement {
  /// Crée un [ScatterPlacement].
  ///
  /// - [offsets] : coin supérieur gauche de chaque élément, dans l'ordre des tailles fournies.
  /// - [height] : hauteur totale occupée par les éléments placés.
  const ScatterPlacement({required this.offsets, required this.height});

  /// Coin supérieur gauche de chaque élément, dans l'ordre des tailles fournies.
  final List<Offset> offsets;

  /// Hauteur totale occupée par les éléments placés.
  final double height;
}

/// Disperse des éléments de tailles [sizes] au hasard sur une largeur [width], sans qu'aucun ne se chevauche.
///
/// Chaque élément, du plus grand au plus petit (les grands sont les plus
/// durs à caser), est « lancé » à une position aléatoire d'une zone dont la
/// hauteur découle de leur surface cumulée. Une position qui chevauche un
/// élément déjà posé est rejetée et l'élément relancé ; après une série
/// d'échecs, la zone s'agrandit. En dernier recours, l'élément est posé sous
/// tous les autres : le résultat ne contient jamais de chevauchement.
///
/// Le hasard est tiré de [seed] : les mêmes entrées donnent toujours le même
/// placement, pour que l'affichage ne saute pas à chaque reconstruction.
///
/// - [sizes] : taille de chaque élément.
/// - [width] : largeur disponible.
/// - [seed] : graine du tirage aléatoire.
/// - [spacing] : espace minimal laissé entre deux éléments.
ScatterPlacement placeScattered({
  required List<Size> sizes,
  required double width,
  required int seed,
  required double spacing,
}) {
  if (sizes.isEmpty) {
    return const ScatterPlacement(offsets: [], height: 0);
  }

  final random = Random(seed);
  final totalArea = sizes.fold<double>(0, (sum, size) => sum + (size.width + spacing) * (size.height + spacing));
  final tallest = sizes.map((size) => size.height).reduce(max);
  var zoneHeight = max(tallest, totalArea * _kLooseness / width);

  final rects = List<Rect?>.filled(sizes.length, null);
  final placedRects = <Rect>[];
  final order = List<int>.generate(sizes.length, (index) => index)
    ..sort((first, second) => _area(sizes[second]).compareTo(_area(sizes[first])));

  for (final index in order) {
    final size = sizes[index];
    Rect? rect;
    for (var attempt = 1; attempt <= _kMaxAttempts && rect == null; attempt++) {
      final candidate =
          Offset(
            random.nextDouble() * max(0, width - size.width),
            random.nextDouble() * max(0, zoneHeight - size.height),
          ) &
          size;
      if (!_overlapsAny(candidate, placedRects, spacing)) {
        rect = candidate;
      }
      if (attempt % _kAttemptsBeforeGrowth == 0) {
        zoneHeight *= _kGrowthFactor;
      }
    }
    rect ??= Offset(random.nextDouble() * max(0, width - size.width), _bottom(placedRects) + spacing) & size;
    rects[index] = rect;
    placedRects.add(rect);
  }

  return ScatterPlacement(offsets: [for (final rect in rects) rect!.topLeft], height: _bottom(placedRects));
}

/// Surface de [size], qui décide de l'ordre de placement.
double _area(Size size) {
  return size.width * size.height;
}

/// Indique si [candidate] empiète sur l'un des [placedRects], marge [spacing] comprise.
bool _overlapsAny(Rect candidate, List<Rect> placedRects, double spacing) {
  final paddedCandidate = candidate.inflate(spacing / 2);
  return placedRects.any((placed) => placed.inflate(spacing / 2).overlaps(paddedCandidate));
}

/// Ordonnée du bas de l'élément le plus bas parmi [rects], `0` s'il n'y en a aucun.
double _bottom(List<Rect> rects) {
  return rects.fold<double>(0, (bottom, rect) => max(bottom, rect.bottom));
}
