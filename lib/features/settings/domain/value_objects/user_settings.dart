import 'package:bedbug/shared/domain/value_object.dart';

/// Paramètres de configuration personnels de l'utilisateur.
class UserSettings extends ValueObject {
  /// Crée un [UserSettings].
  ///
  /// - [blockedUrls] : liste des URLs bloquées (images, liens).
  /// - [blockedWords] : liste des mots bloqués dans les contenus.
  /// - [isAnonymousByDefault] : `true` si les nouveaux contenus sont publiés anonymement par défaut.
  const UserSettings({required this.blockedUrls, required this.blockedWords, this.isAnonymousByDefault = false});

  /// Retourne une instance [UserSettings] avec toutes les listes vides et les options désactivées.
  const UserSettings.empty() : blockedUrls = const [], blockedWords = const [], isAnonymousByDefault = false;

  /// Liste des URLs bloquées par l'utilisateur.
  final List<String> blockedUrls;

  /// Liste des mots bloqués par l'utilisateur.
  final List<String> blockedWords;

  /// Indique si les nouveaux contenus sont publiés anonymement par défaut.
  ///
  /// Ne fixe que la valeur initiale proposée à l'écriture d'un contenu :
  /// l'utilisateur garde la main sur chaque publication.
  final bool isAnonymousByDefault;

  /// Retourne une copie de ces settings avec les champs fournis modifiés.
  UserSettings copyWith({List<String>? blockedUrls, List<String>? blockedWords, bool? isAnonymousByDefault}) {
    return UserSettings(
      blockedUrls: blockedUrls ?? this.blockedUrls,
      blockedWords: blockedWords ?? this.blockedWords,
      isAnonymousByDefault: isAnonymousByDefault ?? this.isAnonymousByDefault,
    );
  }
}
