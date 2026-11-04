import 'package:bedbug/resources/content/storage/storage.config.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Vérifie que la limite de stockage saisie, en mégaoctets, reste dans les bornes autorisées.
///
/// Retourne `null` si vide : déléguer la vérification à `NotEmptyValidator`.
class StorageLimitValidator extends Validator<dynamic> {
  /// Crée un [StorageLimitValidator].
  const StorageLimitValidator() : super();

  /// Retourne l'erreur de la valeur de [control], ou `null` si elle est valide.
  ///
  /// - [control] : contrôle dont la valeur est vérifiée.
  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final value = control.value;
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    final megabytes = int.tryParse(value.trim());
    if (megabytes == null || megabytes < minStorageLimitInMegabytes || megabytes > maxStorageLimitInMegabytes) {
      return {'storageLimit': true};
    }
    return null;
  }
}
