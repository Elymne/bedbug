import 'package:bedbug/usecases/trust/get_trust_settings/get_trust_settings.usecase.dart';

/// Échecs possibles du [GetTrustSettingsUsecase].
enum GetTrustSettingsFailure {
  /// Les réglages lus sont corrompus.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue.
  unknown,
}
