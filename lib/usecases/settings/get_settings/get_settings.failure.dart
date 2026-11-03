import 'package:bedbug/usecases/settings/get_settings/get_settings.usecase.dart';

/// Échecs possibles du [GetSettingsUsecase].
enum GetSettingsFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue.
  unknown,
}
