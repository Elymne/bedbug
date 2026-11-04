import 'package:bedbug/resources/signature/signature/signature.entity.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Vérifie que l'icône ne contient aucun mot (pas de suite de lettres).
///
/// Applique la règle du domaine ([Signature.isValidAvatarText]). Retourne `null` si vide : déléguer la vérification à
/// `NotEmptyValidator`.
class AvatarTextValidator extends Validator<dynamic> {
  /// Crée un [AvatarTextValidator].
  const AvatarTextValidator() : super();

  /// Retourne l'erreur de la valeur de [control], ou `null` si elle est valide.
  ///
  /// - [control] : contrôle dont la valeur est vérifiée.
  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    if (!Signature.isValidAvatarText(value)) {
      return {'avatarText': true};
    }
    return null;
  }
}
