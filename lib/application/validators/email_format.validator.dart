import 'package:reactive_forms/reactive_forms.dart';

/// Vérifie que la valeur correspond au format d'une adresse email.
///
/// Retourne `null` si vide : déléguer la vérification à `NotEmptyValidator`.
class EmailFormatValidator extends Validator<dynamic> {
  /// Crée un [EmailFormatValidator].
  const EmailFormatValidator() : super();

  /// Retourne l'erreur de la valeur de [control], ou `null` si elle est valide.
  ///
  /// - [control] : contrôle dont la valeur est vérifiée.
  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return {'email': true};
    }
    return null;
  }
}
