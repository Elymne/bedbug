import 'package:bedbug/resources/signature/signature/signature.entity.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Vérifie que le pseudo ne contient que des lettres non accentuées et des tirets, sur 3 caractères minimum.
///
/// Applique la règle du domaine ([Signature.isValidPseudo]). Retourne `null` si vide : déléguer la vérification à
/// `NotEmptyValidator`.
class PseudoValidator extends Validator<dynamic> {
  /// Crée un [PseudoValidator].
  const PseudoValidator() : super();

  /// Retourne l'erreur de la valeur de [control], ou `null` si elle est valide.
  ///
  /// - [control] : contrôle dont la valeur est vérifiée.
  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    if (!Signature.isValidPseudo(value.trim())) {
      return {'pseudo': true};
    }
    return null;
  }
}
