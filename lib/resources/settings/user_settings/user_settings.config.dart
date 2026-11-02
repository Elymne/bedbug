import 'package:bedbug/resources/settings/user_settings/user_settings.entity.dart';

/// Nom de la box Hive des réglages de l'utilisateur.
const String userSettingsBoxName = 'user_settings';

/// Réglages d'un appareil qui n'a encore rien configuré : aucun blocage, publication signée, échange coupé.
///
/// Sert de point de départ au premier enregistrement, et de repli tant que les réglages n'ont pas pu être lus.
final UserSettings defaultUserSettings = UserSettings(
  id: '',
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  blockedUrls: const [],
  blockedWords: const [],
);
