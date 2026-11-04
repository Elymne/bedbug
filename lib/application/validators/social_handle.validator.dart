import 'package:bedbug/resources/signature/signature/social_network.enum.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Vérifie que l'identifiant saisi est valide sur un réseau social donné.
///
/// L'identifiant dépend du réseau (format Twitter, Twitch, GitHub…, URL collée qui doit pointer vers ce réseau) : le
/// réseau est donc fourni à la création du validator. Retourne `null` si vide : déléguer la vérification à
/// `NotEmptyValidator`.
class SocialHandleValidator extends Validator<dynamic> {
  /// Crée un [SocialHandleValidator].
  ///
  /// - [network] : réseau sur lequel l'identifiant doit être valide.
  const SocialHandleValidator(this.network) : super();

  /// Réseau sur lequel l'identifiant doit être valide.
  final SocialNetwork network;

  /// Retourne l'erreur de la valeur de [control], ou `null` si elle est valide.
  ///
  /// - [control] : contrôle dont la valeur est vérifiée.
  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    if (network.normalizeHandle(value) == null) {
      return {'socialHandle': true};
    }
    return null;
  }
}
