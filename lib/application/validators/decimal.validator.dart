import 'package:reactive_forms/reactive_forms.dart';

/// Vérifie que la valeur est un nombre décimal valide.
///
/// Accepte `.` ou `,` comme séparateur. Retourne `null` si vide.
class DecimalValidator extends Validator<dynamic> {
  /// Crée un [DecimalValidator].
  const DecimalValidator() : super();

  /// Retourne l'erreur de la valeur de [control], ou `null` si elle est valide.
  ///
  /// - [control] : contrôle dont la valeur est vérifiée.
  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value is! String || value.isEmpty) {
      return null;
    }
    if (!RegExp(r'^\d+([.,]\d+)?$').hasMatch(value.trim())) {
      return {'decimal': true};
    }
    return null;
  }
}
