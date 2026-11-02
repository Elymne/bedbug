import 'package:bedbug/core/domain/value_object.dart';
import 'package:bedbug/resources/content/drawing/drawing.config.dart';

/// Dessin vectoriel : une taille et une orientation de surface, une palette, et la liste des opérations qui le
/// composent.
///
/// Les limites (couleurs, opérations, points) sont vérifiées par
/// `DrawingValidationService`, à la création comme à la réception. La taille
/// du repère qui en découle est donnée par `DrawingDimensionsExtension`.
class Drawing extends ValueObject {
  /// Crée un [Drawing].
  ///
  /// - [size] : taille de la surface.
  /// - [orientation] : orientation de la surface.
  /// - [palette] : couleurs ARGB opaques, exactement [drawingPaletteSize].
  /// - [operations] : opérations, dans l'ordre où elles sont rejouées.
  const Drawing({
    this.size = DrawingSize.medium,
    this.orientation = DrawingOrientation.landscape,
    required this.palette,
    required this.operations,
  });

  /// Dessin vide, de taille moyenne en paysage, avec la palette par défaut.
  const Drawing.empty()
    : size = DrawingSize.medium,
      orientation = DrawingOrientation.landscape,
      palette = defaultDrawingPalette,
      operations = const [];

  /// Taille de la surface.
  final DrawingSize size;

  /// Orientation de la surface.
  final DrawingOrientation orientation;

  /// Couleurs ARGB opaques de la palette.
  final List<int> palette;

  /// Opérations, dans l'ordre où elles sont rejouées.
  final List<DrawingOperation> operations;

  /// Retourne une copie de ce dessin avec les champs fournis modifiés.
  ///
  /// - [size] : nouvelle taille.
  /// - [orientation] : nouvelle orientation.
  /// - [palette] : nouvelle palette.
  /// - [operations] : nouvelles opérations.
  Drawing copyWith({
    DrawingSize? size,
    DrawingOrientation? orientation,
    List<int>? palette,
    List<DrawingOperation>? operations,
  }) {
    return Drawing(
      size: size ?? this.size,
      orientation: orientation ?? this.orientation,
      palette: palette ?? this.palette,
      operations: operations ?? this.operations,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Drawing &&
        other.size == size &&
        other.orientation == orientation &&
        _isSameList(other.palette, palette) &&
        _isSameList(other.operations, operations);
  }

  @override
  int get hashCode {
    return Object.hash(size, orientation, Object.hashAll(palette), Object.hashAll(operations));
  }
}

/// Taille de la surface d'un [Drawing] : la longueur de ses côtés, en points, toujours au rapport 4:3.
///
/// Les pinceaux gardent le même diamètre en points quelle que soit la
/// taille : une grande surface laisse donc la place à plus de détails, que
/// l'on dessine en zoomant.
enum DrawingSize {
  /// Petite surface, 768 × 576 points.
  small(0, 768, 576),

  /// Surface moyenne, 1024 × 768 points : celle de tous les dessins d'avant le choix de la taille.
  medium(1, 1024, 768),

  /// Grande surface, 1536 × 1152 points.
  large(2, 1536, 1152);

  /// Crée une [DrawingSize].
  ///
  /// - [value] : valeur entière stockée et transmise.
  /// - [longSide] : longueur du grand côté, en points.
  /// - [shortSide] : longueur du petit côté, en points.
  const DrawingSize(this.value, this.longSide, this.shortSide);

  /// Valeur entière stockée et transmise. Stable indépendamment de l'ordre de déclaration.
  final int value;

  /// Longueur du grand côté, en points.
  final int longSide;

  /// Longueur du petit côté, en points.
  final int shortSide;

  /// Retourne la taille correspondant à [value], ou `null` si elle est inconnue.
  ///
  /// - [value] : valeur entière stockée.
  static DrawingSize? fromValue(int value) {
    for (final size in DrawingSize.values) {
      if (size.value == value) {
        return size;
      }
    }
    return null;
  }
}

/// Orientation de la surface d'un [Drawing].
enum DrawingOrientation {
  /// Paysage : le grand côté est la largeur.
  landscape(0),

  /// Portrait : le grand côté est la hauteur.
  portrait(1);

  /// Crée une [DrawingOrientation].
  ///
  /// - [value] : valeur entière stockée et transmise.
  const DrawingOrientation(this.value);

  /// Valeur entière stockée et transmise. Stable indépendamment de l'ordre de déclaration.
  final int value;

  /// Retourne l'orientation correspondant à [value], ou `null` si elle est inconnue.
  ///
  /// - [value] : valeur entière stockée.
  static DrawingOrientation? fromValue(int value) {
    for (final orientation in DrawingOrientation.values) {
      if (orientation.value == value) {
        return orientation;
      }
    }
    return null;
  }
}

/// Indique si [first] et [second] contiennent les mêmes éléments, dans le même ordre.
bool _isSameList(List<Object> first, List<Object> second) {
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

/// Opération d'un dessin : un trait de pinceau, ou un remplissage.
///
/// Un dessin n'est pas une image mais la liste de ses opérations, rejouées
/// dans l'ordre à l'affichage : c'est léger à transmettre, impossible à
/// confondre avec un fichier image, et annuler revient à retirer la
/// dernière opération.
sealed class DrawingOperation {
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

/// Point d'un dessin, en coordonnées entières du repère du dessin (voir `DrawingDimensionsExtension`).
///
/// Des entiers dans un repère fixe, plutôt que des pixels d'écran : un
/// dessin s'affiche à l'identique sur tous les téléphones, et se transmet
/// sous une forme compacte.
class DrawingPoint {
  /// Crée un [DrawingPoint].
  ///
  /// - [x] : abscisse, de 0 à la largeur du repère moins 1.
  /// - [y] : ordonnée, de 0 à la hauteur du repère moins 1.
  const DrawingPoint(this.x, this.y);

  /// Abscisse, de 0 à la largeur du repère moins 1.
  final int x;

  /// Ordonnée, de 0 à la hauteur du repère moins 1.
  final int y;

  @override
  bool operator ==(Object other) {
    return other is DrawingPoint && other.x == x && other.y == y;
  }

  @override
  int get hashCode {
    return Object.hash(x, y);
  }

  @override
  String toString() {
    return '($x, $y)';
  }
}
