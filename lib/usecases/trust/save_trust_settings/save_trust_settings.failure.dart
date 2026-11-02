import 'package:bedbug/usecases/trust/save_trust_settings/save_trust_settings.usecase.dart';

/// Échecs possibles du [SaveTrustSettingsUsecase].
enum SaveTrustSettingsFailure {
  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue.
  unknown,
}
