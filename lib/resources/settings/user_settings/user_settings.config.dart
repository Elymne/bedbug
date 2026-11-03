import 'package:bedbug/resources/settings/user_settings/user_settings.value_object.dart';

/// Nom de la box Hive des réglages de l'utilisateur.
const String userSettingsBoxName = 'user_settings';

/// Réglages d'un appareil qui n'a encore rien configuré : aucun blocage, publication signée, échange coupé.
///
/// Sert de point de départ au premier enregistrement, et de repli tant que les réglages n'ont pas pu être lus.
const UserSettings defaultUserSettings = UserSettings(blockedUrls: [], blockedWords: []);
