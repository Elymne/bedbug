import 'package:bedbug/features/content/domain/object_values/drawing_operation.dart';
import 'package:bedbug/shared/domain/value_object.dart';

/// Largeur du repère d'un dessin, en points.
const int drawingWidth = 1024;

/// Hauteur du repère d'un dessin, en points (format 4:3).
const int drawingHeight = 768;

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

/// Dessin vectoriel : une palette, et la liste des opérations qui le composent.
///
/// Les limites (couleurs, opérations, points) sont vérifiées par
/// `DrawingValidationService`, à la création comme à la réception.
class Drawing extends ValueObject {
  /// Crée un [Drawing].
  ///
  /// - [palette] : couleurs ARGB opaques, exactement [drawingPaletteSize].
  /// - [operations] : opérations, dans l'ordre où elles sont rejouées.
  const Drawing({required this.palette, required this.operations});

  /// Dessin vide, avec la palette par défaut.
  const Drawing.empty() : palette = defaultDrawingPalette, operations = const [];

  /// Couleurs ARGB opaques de la palette.
  final List<int> palette;

  /// Opérations, dans l'ordre où elles sont rejouées.
  final List<DrawingOperation> operations;

  /// Retourne une copie de ce dessin avec les champs fournis modifiés.
  ///
  /// - [palette] : nouvelle palette.
  /// - [operations] : nouvelles opérations.
  Drawing copyWith({List<int>? palette, List<DrawingOperation>? operations}) {
    return Drawing(palette: palette ?? this.palette, operations: operations ?? this.operations);
  }

  @override
  bool operator ==(Object other) {
    return other is Drawing && _isSameList(other.palette, palette) && _isSameList(other.operations, operations);
  }

  @override
  int get hashCode {
    return Object.hash(Object.hashAll(palette), Object.hashAll(operations));
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
