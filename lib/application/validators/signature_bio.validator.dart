import 'package:bedbug/resources/signature/signature/signature.entity.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Vérifie que la description d'une signature tient sur une ligne et ne dépasse pas sa longueur maximale.
///
/// Applique la règle du domaine ([Signature.isValidBio]). Retourne `null` si vide : la description est optionnelle.
class SignatureBioValidator extends Validator<dynamic> {
  /// Crée un [SignatureBioValidator].
  const SignatureBioValidator() : super();

  /// Retourne l'erreur de la valeur de [control], ou `null` si elle est valide.
  ///
  /// - [control] : contrôle dont la valeur est vérifiée.
  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    if (!Signature.isValidBio(value.trim())) {
      return {'signatureBio': true};
    }
    return null;
  }
}
