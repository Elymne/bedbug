import 'package:bedbug/features/settings/domain/value_objects/user_settings.dart';

/// Contrat du repository gérant les [UserSettings].
///
/// Ce repository gère un unique objet de configuration.
abstract class SettingsRepository {
  /// Retourne les settings persistés, ou `null` si jamais initialisés.
  Future<UserSettings?> getUnique(String id);

  /// Persiste les [UserSettings] fournis.
  Future<UserSettings> addOne(UserSettings entity);

  /// Met à jour les [UserSettings] existants.
  ///
  /// Lève une `DatasourceException` si aucun settings n'a encore été persisté.
  Future<UserSettings> updateOne(UserSettings entity);
}
