import 'package:bedbug/features/content/domain/object_values/drawing.dart';
import 'package:bedbug/features/content/domain/object_values/drawing_operation.dart';
import 'package:bedbug/features/content/domain/object_values/drawing_point.dart';
import 'package:bedbug/shared/domain/service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [DrawingValidationService].
final drawingValidationServiceProvider = Provider<DrawingValidationService>((ref) {
  return const DrawingValidationService();
});

/// Vérifie qu'un dessin respecte toutes les limites d'un dessin, avant de l'enregistrer ou de l'afficher.
///
/// Un dessin reçu d'un pair peut avoir été fabriqué à la main : des milliers
/// de couleurs pour reproduire une photo, des millions de points pour
/// saturer le téléphone, des positions hors du repère. Chaque limite est
/// vérifiée, et le dessin entier est refusé dès qu'une seule est dépassée,
/// plutôt que d'essayer de le corriger.
class DrawingValidationService extends Service {
  /// Crée un [DrawingValidationService].
  const DrawingValidationService();

  /// Indique si [drawing] respecte toutes les limites.
  ///
  /// - [drawing] : dessin à vérifier.
  bool isValid(Drawing drawing) {
    if (drawing.palette.length != drawingPaletteSize) {
      return false;
    }
    // Couleurs opaques uniquement : la transparence ne sert qu'au feutre, géré par l'app.
    if (drawing.palette.any((color) => color < 0xFF000000 || color > 0xFFFFFFFF)) {
      return false;
    }
    if (drawing.operations.length > maxDrawingOperations) {
      return false;
    }

    var fillCount = 0;
    var pointCount = 0;
    for (final operation in drawing.operations) {
      if (operation.layer < 0 || operation.layer >= drawingLayerCount) {
        return false;
      }
      if (operation.colorIndex < 0 || operation.colorIndex >= drawingPaletteSize) {
        return false;
      }
      switch (operation) {
        case DrawingFill(:final point):
          fillCount++;
          if (fillCount > maxDrawingFills || !isInside(point)) {
            return false;
          }
        case DrawingStroke(:final size, :final seed, :final points):
          pointCount += points.length;
          if (size < 0 || size >= drawingBrushSizeCount || seed < 0 || seed > maxDrawingSeed) {
            return false;
          }
          if (points.isEmpty || points.length > maxDrawingStrokePoints || pointCount > maxDrawingPoints) {
            return false;
          }
          if (!points.every(isInside)) {
            return false;
          }
      }
    }
    return true;
  }

  /// Indique si [point] est dans le repère du dessin.
  ///
  /// - [point] : point à vérifier.
  bool isInside(DrawingPoint point) {
    return point.x >= 0 && point.x < drawingWidth && point.y >= 0 && point.y < drawingHeight;
  }
}
