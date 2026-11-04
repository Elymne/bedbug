import 'package:reactive_forms/reactive_forms.dart';

/// Vérifie que le champ n'est pas vide ou nul.
///
/// Une liste vide (ex. aucune image choisie) est considérée comme vide.
class NotEmptyValidator extends Validator<dynamic> {
  /// Crée un [NotEmptyValidator].
  const NotEmptyValidator() : super();

  /// Retourne l'erreur de la valeur de [control], ou `null` si elle est valide.
  ///
  /// - [control] : contrôle dont la valeur est vérifiée.
  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value == null) {
      return {'required': true};
    }
    if (value is String && value.trim().isEmpty) {
      return {'required': true};
    }
    if (value is Iterable<dynamic> && value.isEmpty) {
      return {'required': true};
    }
    return null;
  }
}
