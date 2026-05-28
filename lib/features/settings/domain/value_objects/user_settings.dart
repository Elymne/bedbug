import 'package:bedbug/shared/domain/value_object.dart';

/// Paramètres de configuration personnels de l'utilisateur.
class UserSettings extends ValueObject {
  /// Crée un [UserSettings].
  ///
  /// - [blockedUrls] : liste des URLs bloquées (images, liens).
  /// - [blockedWords] : liste des mots bloqués dans les contenus.
  const UserSettings({
    required this.blockedUrls,
    required this.blockedWords,
  });

  /// Retourne une instance [UserSettings] avec toutes les listes vides.
  const UserSettings.empty()
      : blockedUrls = const [],
        blockedWords = const [];

  /// Liste des URLs bloquées par l'utilisateur.
  final List<String> blockedUrls;

  /// Liste des mots bloqués par l'utilisateur.
  final List<String> blockedWords;

  /// Retourne une copie de ces settings avec les champs fournis modifiés.
  UserSettings copyWith({
    List<String>? blockedUrls,
    List<String>? blockedWords,
  }) {
    return UserSettings(
      blockedUrls: blockedUrls ?? this.blockedUrls,
      blockedWords: blockedWords ?? this.blockedWords,
    );
  }
}
