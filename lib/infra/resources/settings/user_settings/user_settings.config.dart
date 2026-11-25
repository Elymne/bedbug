import 'package:bedbug/infra/resources/settings/user_settings/user_settings.value_object.dart';

/// Réglages d'un appareil qui n'a encore rien configuré : aucun blocage, publication signée, échange coupé.
///
/// Sert de point de départ au premier enregistrement, et de repli tant que les réglages n'ont pas pu être lus.
const UserSettings defaultUserSettings = UserSettings(blockedUrls: [], blockedWords: []);
