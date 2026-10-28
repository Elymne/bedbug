import 'package:bedbug/features/content/domain/object_values/trust_settings.dart';

/// Stockage des réglages de confiance de l'utilisateur, un seul jeu par appareil.
abstract class TrustSettingsRepository {
  /// Retourne les réglages enregistrés, ou `null` si l'utilisateur n'a encore rien modifié.
  Future<TrustSettings?> get();

  /// Enregistre [settings] à la place des réglages actuels.
  ///
  /// - [settings] : réglages à enregistrer.
  Future<void> save(TrustSettings settings);

  /// Efface les réglages enregistrés, pour revenir aux réglages par défaut.
  Future<void> clear();
}
