import 'package:bedbug/resources/settings/user_settings/user_settings.value_object.dart';

/// Contrat du repository gérant les [UserSettings].
///
/// Ce repository gère un unique jeu de réglages, toujours remplacé en entier.
abstract class UserSettingsRepository {
  /// Retourne les réglages persistés, ou `null` s'ils n'ont jamais été enregistrés.
  Future<UserSettings?> get();

  /// Enregistre [settings], à la place des réglages précédents.
  ///
  /// - [settings] : réglages à enregistrer.
  Future<void> save(UserSettings settings);
}
