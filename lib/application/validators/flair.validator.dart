import 'package:bedbug/resources/content/content/content.extension.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Vérifie qu'il reste un flair exploitable une fois la saisie normalisée.
///
/// Plus strict que `NotEmptyValidator` : une saisie réduite à `/` ou à des espaces est refusée, car elle ne produirait
/// aucun flair après normalisation.
class FlairValidator extends Validator<dynamic> {
  /// Crée un [FlairValidator].
  const FlairValidator() : super();

  /// Retourne l'erreur de la valeur de [control], ou `null` si elle est valide.
  ///
  /// - [control] : contrôle dont la valeur est vérifiée.
  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value is! String || value.toFlair() == null) {
      return {'required': true};
    }
    return null;
  }
}
