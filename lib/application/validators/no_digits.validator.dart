import 'package:reactive_forms/reactive_forms.dart';

/// Vérifie que la valeur ne contient aucun chiffre.
///
/// Retourne `null` si vide : déléguer la vérification à `NotEmptyValidator`.
class NoDigitsValidator extends Validator<dynamic> {
  /// Crée un [NoDigitsValidator].
  const NoDigitsValidator() : super();

  /// Retourne l'erreur de la valeur de [control], ou `null` si elle est valide.
  ///
  /// - [control] : contrôle dont la valeur est vérifiée.
  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value is! String || value.isEmpty) {
      return null;
    }
    if (RegExp(r'\d').hasMatch(value)) {
      return {'noDigits': true};
    }
    return null;
  }
}
