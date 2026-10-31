import 'package:bedbug/features/content/domain/object_values/drawing_operation.dart';
import 'package:bedbug/shared/domain/value_object.dart';

/// Nombre de calques d'un dessin.
const int drawingLayerCount = 3;

/// Nombre de tailles de pinceau.
const int drawingBrushSizeCount = 4;

/// Nombre de couleurs d'une palette.
///
/// C'est le verrou le plus efficace contre une photo convertie en dessin :
/// une photo a besoin de milliers de nuances, et n'est plus qu'une affiche
/// grossière avec 16.
const int drawingPaletteSize = 16;

/// Nombre maximal d'opérations (traits et remplissages) d'un dessin.
const int maxDrawingOperations = 500;

/// Nombre maximal de remplissages d'un dessin : chacun demande de recalculer une zone à l'affichage.
const int maxDrawingFills = 50;

/// Nombre maximal de points d'un trait.
const int maxDrawingStrokePoints = 1000;

/// Nombre maximal de points d'un dessin, tous traits confondus.
const int maxDrawingPoints = 20000;

/// Plus grande graine acceptée (entier non signé sur 32 bits).
const int maxDrawingSeed = 0xFFFFFFFF;

/// Palette proposée pour un nouveau dessin, en couleurs ARGB opaques.
const List<int> defaultDrawingPalette = [
  0xFF1A1A1A, // noir
  0xFFFFFFFF, // blanc
  0xFF8C8C8C, // gris
  0xFF4A4A4A, // gris foncé
  0xFFE53935, // rouge
  0xFFFB8C00, // orange
  0xFFFDD835, // jaune
  0xFF7CB342, // vert
  0xFF2E7D32, // vert foncé
  0xFF26C6DA, // cyan
  0xFF1E88E5, // bleu
  0xFF283593, // bleu nuit
  0xFF8E24AA, // violet
  0xFFF48FB1, // rose
  0xFF795548, // marron
  0xFFFFE0B2, // beige
];

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
