import 'package:reactive_forms/reactive_forms.dart';

/// Vérifie que le mot de passe contient au moins 6 caractères.
///
/// Retourne `null` si vide : déléguer la vérification à `NotEmptyValidator`.
class PasswordValidator extends Validator<dynamic> {
  /// Crée un [PasswordValidator].
  const PasswordValidator() : super();

  /// Retourne l'erreur de la valeur de [control], ou `null` si elle est valide.
  ///
  /// - [control] : contrôle dont la valeur est vérifiée.
  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value is! String || value.isEmpty) {
      return null;
    }
    if (value.length < 6) {
      return {'minLength': true};
    }
    return null;
  }
}
