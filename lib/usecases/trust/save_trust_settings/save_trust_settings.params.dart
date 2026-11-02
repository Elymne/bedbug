import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/resources/content/trust_settings/trust_settings.value_object.dart';
import 'package:bedbug/usecases/trust/save_trust_settings/save_trust_settings.usecase.dart';

/// Paramètres du [SaveTrustSettingsUsecase].
class SaveTrustSettingsParams extends Params {
  /// Crée des [SaveTrustSettingsParams].
  ///
  /// - [settings] : réglages à enregistrer, `null` pour revenir aux réglages par défaut.
  const SaveTrustSettingsParams({required this.settings});

  /// Réglages à enregistrer, `null` pour revenir aux réglages par défaut.
  final TrustSettings? settings;
}
