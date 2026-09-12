import 'package:bedbug/features/content/domain/enums/tag.dart';

/// Couleur associée à un [Tag], indépendante de toute palette concrète.
///
/// Le domaine ne connaît que cette clé sémantique ; la correspondance vers
/// une couleur réelle (`AppColors`) est faite par la couche application.
enum TagColor {
  /// Couleur associée aux tags de type information.
  blue(0),

  /// Couleur associée aux tags de type alerte.
  red(1),

  /// Couleur associée aux tags de type question.
  purple(2),

  /// Couleur associée aux tags de type divulgâchage.
  orange(3);

  const TagColor(this.value);

  /// Valeur entière persistée. Stable indépendamment de l'ordre de déclaration.
  final int value;
}
