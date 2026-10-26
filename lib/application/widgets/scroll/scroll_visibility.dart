import 'package:flutter/widgets.dart';

/// Tolérance, en pixels, sur les bords de la zone visible, pour absorber les arrondis de position.
const double _kEdgeTolerance = 0.5;

/// Position d'un widget par rapport à la zone visible de son défilement.
enum ScrollVisibility {
  /// Entièrement hors de la zone visible.
  hidden,

  /// En partie dans la zone visible : il y entre ou en sort.
  partial,

  /// Entièrement dans la zone visible.
  full,
}

/// Retourne la position du widget de [context] par rapport à la zone visible de [scrollable].
///
/// Partagé par les widgets qui réagissent au défilement (pause des
/// animations hors écran, apparition à l'écran) pour qu'ils s'accordent sur
/// ce que « visible » veut dire. Retourne `null` tant que le widget ou le
/// défilement n'a pas encore de taille (avant la première mise en page).
///
/// - [context] : contexte du widget dont on veut la position.
/// - [scrollable] : défilement dans lequel il se trouve.
/// - [margin] : marge ajoutée autour de la zone visible, pour anticiper l'entrée à l'écran (défaut 0).
ScrollVisibility? scrollVisibilityOf(BuildContext context, ScrollableState scrollable, {double margin = 0}) {
  final box = context.findRenderObject();
  final viewport = scrollable.context.findRenderObject();
  if (box is! RenderBox || viewport is! RenderBox || !box.hasSize || !viewport.hasSize) {
    return null;
  }
  final rect = box.localToGlobal(Offset.zero) & box.size;
  final viewportRect = (viewport.localToGlobal(Offset.zero) & viewport.size).inflate(margin);
  if (!rect.overlaps(viewportRect)) {
    return ScrollVisibility.hidden;
  }
  // Bords inclus, contrairement à `Rect.contains` : un élément collé au bord
  // droit ou bas de la zone visible y est bien entièrement.
  final isContained =
      rect.left >= viewportRect.left - _kEdgeTolerance &&
      rect.top >= viewportRect.top - _kEdgeTolerance &&
      rect.right <= viewportRect.right + _kEdgeTolerance &&
      rect.bottom <= viewportRect.bottom + _kEdgeTolerance;
  if (isContained) {
    return ScrollVisibility.full;
  }
  return ScrollVisibility.partial;
}
