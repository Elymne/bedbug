import 'package:bedbug/resources/url/safe_url/safe_url.value_object.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Vérifie que l'adresse est une URL https sans piège (voir [SafeUrl.parse]).
///
/// Les espaces autour sont ignorés : ils viennent souvent d'un copier-coller. Retourne `null` si vide : déléguer la
/// vérification à `NotEmptyValidator`.
class SafeUrlValidator extends Validator<dynamic> {
  /// Crée un [SafeUrlValidator].
  const SafeUrlValidator() : super();

  /// Retourne l'erreur de la valeur de [control], ou `null` si elle est valide.
  ///
  /// - [control] : contrôle dont la valeur est vérifiée.
  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    if (SafeUrl.parse(value.trim()) == null) {
      return {'safeUrl': true};
    }
    return null;
  }
}
