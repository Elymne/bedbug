import 'package:bedbug/resources/content/reaction/reaction.entity.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Vérifie que la bulle d'une réaction tient sur une ligne et ne dépasse pas sa longueur maximale.
///
/// Applique la règle du domaine ([Reaction.isValidBubble]). Retourne `null` si vide : déléguer la vérification à
/// `NotEmptyValidator`.
class ReactionBubbleValidator extends Validator<dynamic> {
  /// Crée un [ReactionBubbleValidator].
  const ReactionBubbleValidator() : super();

  /// Retourne l'erreur de la valeur de [control], ou `null` si elle est valide.
  ///
  /// - [control] : contrôle dont la valeur est vérifiée.
  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    if (!Reaction.isValidBubble(value.trim())) {
      return {'reactionBubble': true};
    }
    return null;
  }
}
