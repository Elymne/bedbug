import 'package:bedbug/shared/domain/value_object.dart';

/// Point d'un dessin, en coordonnées entières du repère du dessin (voir `DrawingDimensionsExtension`).
///
/// Des entiers dans un repère fixe, plutôt que des pixels d'écran : un
/// dessin s'affiche à l'identique sur tous les téléphones, et se transmet
/// sous une forme compacte.
class DrawingPoint extends ValueObject {
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
