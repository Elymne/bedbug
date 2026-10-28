import 'package:bedbug/features/content/domain/object_values/drawing_point.dart';
import 'package:bedbug/shared/domain/value_object.dart';

/// Opération d'un dessin : un trait de pinceau, ou un remplissage.
///
/// Un dessin n'est pas une image mais la liste de ses opérations, rejouées
/// dans l'ordre à l'affichage : c'est léger à transmettre, impossible à
/// confondre avec un fichier image, et annuler revient à retirer la
/// dernière opération.
sealed class DrawingOperation extends ValueObject {
  /// Crée une [DrawingOperation].
  ///
  /// - [layer] : calque sur lequel l'opération s'applique, de 0 (fond) à `drawingLayerCount - 1`.
  /// - [colorIndex] : position de la couleur dans la palette du dessin.
  const DrawingOperation({required this.layer, required this.colorIndex});

  /// Calque sur lequel l'opération s'applique, de 0 (fond) à `drawingLayerCount - 1`.
  final int layer;

  /// Position de la couleur dans la palette du dessin.
  ///
  /// Une position plutôt qu'une couleur : changer une couleur de la palette
  /// recolore tout ce qui a été dessiné avec.
  final int colorIndex;
}

/// Trait de pinceau, tracé à travers une suite de points.
class DrawingStroke extends DrawingOperation {
  /// Crée un [DrawingStroke].
  ///
  /// - [layer] : calque du trait.
  /// - [colorIndex] : position de la couleur dans la palette (ignorée par la gomme).
  /// - [brush] : pinceau utilisé.
  /// - [size] : taille du pinceau, de 0 à `drawingBrushSizeCount - 1`.
  /// - [seed] : graine du grain du crayon et des points de la bombe, pour un rendu identique sur tous les téléphones.
  /// - [points] : points du trait, dans l'ordre du tracé (au moins un).
  const DrawingStroke({
    required super.layer,
    required super.colorIndex,
    required this.brush,
    required this.size,
    required this.seed,
    required this.points,
  });

  /// Pinceau utilisé.
  final DrawingBrush brush;

  /// Taille du pinceau, de 0 à `drawingBrushSizeCount - 1`.
  ///
  /// Une taille parmi quelques-unes, plutôt qu'une épaisseur libre : un trait
  /// ne peut pas être assez fin pour reproduire une photo pixel par pixel.
  final int size;

  /// Graine du grain du crayon et des points de la bombe.
  final int seed;

  /// Points du trait, dans l'ordre du tracé.
  final List<DrawingPoint> points;

  @override
  bool operator ==(Object other) {
    return other is DrawingStroke &&
        other.layer == layer &&
        other.colorIndex == colorIndex &&
        other.brush == brush &&
        other.size == size &&
        other.seed == seed &&
        _isSamePoints(other.points, points);
  }

  @override
  int get hashCode {
    return Object.hash(layer, colorIndex, brush, size, seed, Object.hashAll(points));
  }
}

/// Remplissage de la zone qui entoure un point, comme un pot de peinture.
///
/// Seul le point de départ est stocké : la zone est recalculée à
/// l'affichage, d'après ce qui est déjà dessiné sur tous les calques.
class DrawingFill extends DrawingOperation {
  /// Crée un [DrawingFill].
  ///
  /// - [layer] : calque qui reçoit la couleur.
  /// - [colorIndex] : position de la couleur dans la palette.
  /// - [point] : point de départ du remplissage.
  const DrawingFill({required super.layer, required super.colorIndex, required this.point});

  /// Point de départ du remplissage.
  final DrawingPoint point;

  @override
  bool operator ==(Object other) {
    return other is DrawingFill && other.layer == layer && other.colorIndex == colorIndex && other.point == point;
  }

  @override
  int get hashCode {
    return Object.hash(layer, colorIndex, point);
  }
}

/// Pinceau d'un [DrawingStroke].
enum DrawingBrush {
  /// Trait rond et plein, dont l'épaisseur suit la vitesse du tracé.
  pen(0),

  /// Trait large et semi-transparent.
  marker(1),

  /// Trait fin et granuleux.
  pencil(2),

  /// Nuage de petits points autour du tracé.
  spray(3),

  /// Efface ce qui a été dessiné sur le calque du trait.
  eraser(4);

  const DrawingBrush(this.value);

  /// Valeur entière stockée et transmise. Stable indépendamment de l'ordre de déclaration.
  final int value;

  /// Retourne le pinceau correspondant à [value], ou `null` s'il est inconnu.
  ///
  /// - [value] : valeur entière stockée.
  static DrawingBrush? fromValue(int value) {
    for (final brush in DrawingBrush.values) {
      if (brush.value == value) {
        return brush;
      }
    }
    return null;
  }
}

/// Indique si [first] et [second] contiennent les mêmes points, dans le même ordre.
bool _isSamePoints(List<DrawingPoint> first, List<DrawingPoint> second) {
  if (first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) {
      return false;
    }
  }
  return true;
}
