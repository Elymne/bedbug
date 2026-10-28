import 'package:bedbug/features/content/domain/object_values/drawing.dart';

/// Dimensions du repère d'un [Drawing], déduites de sa taille et de son orientation.
///
/// Une extension plutôt qu'un champ : le repère découle toujours de la
/// taille et de l'orientation, il ne peut pas les contredire. Sert partout où
/// un point est placé ou vérifié : l'éditeur, la vérification, le rendu.
extension DrawingDimensionsExtension on Drawing {
  /// Largeur du repère, en points.
  int get width {
    return orientation == DrawingOrientation.landscape ? size.longSide : size.shortSide;
  }

  /// Hauteur du repère, en points.
  int get height {
    return orientation == DrawingOrientation.landscape ? size.shortSide : size.longSide;
  }
}
