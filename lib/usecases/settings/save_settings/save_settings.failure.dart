import 'package:bedbug/usecases/settings/save_settings/save_settings.usecase.dart';

/// Échecs possibles du [SaveSettingsUsecase].
enum SaveSettingsFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue.
  unknown,
}
