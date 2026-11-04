import 'package:reactive_forms/reactive_forms.dart';

/// Vérifie que la valeur décimale est positive ou nulle.
///
/// Retourne `null` si non parseable : déléguer la vérification à `DecimalValidator`.
class NotNegativeValidator extends Validator<dynamic> {
  /// Crée un [NotNegativeValidator].
  const NotNegativeValidator() : super();

  /// Retourne l'erreur de la valeur de [control], ou `null` si elle est valide.
  ///
  /// - [control] : contrôle dont la valeur est vérifiée.
  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value is! String || value.isEmpty) {
      return null;
    }
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed != null && parsed < 0) {
      return {'notNegative': true};
    }
    return null;
  }
}
