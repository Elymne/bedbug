import 'package:bedbug/core/domain/value_object.dart';

/// Paramètres de configuration personnels de l'utilisateur.
///
/// Un seul jeu de réglages par appareil, toujours remplacé en entier : il n'a pas d'identité à suivre, c'est un value
/// object.
class UserSettings extends ValueObject {
  /// Crée un [UserSettings].
  ///
  /// - [blockedUrls] : liste des URLs bloquées (images, liens).
  /// - [blockedWords] : liste des mots bloqués dans les contenus.
  /// - [isAnonymousByDefault] : `true` si les nouveaux contenus sont publiés anonymement par défaut.
  /// - [isExchangeEnabled] : `true` si l'échange avec les téléphones proches est activé.
  const UserSettings({
    required this.blockedUrls,
    required this.blockedWords,
    this.isAnonymousByDefault = false,
    this.isExchangeEnabled = false,
  });

  /// Liste des URLs bloquées par l'utilisateur.
  final List<String> blockedUrls;

  /// Liste des mots bloqués par l'utilisateur.
  final List<String> blockedWords;

  /// Indique si les nouveaux contenus sont publiés anonymement par défaut.
  ///
  /// Ne fixe que la valeur initiale proposée à l'écriture d'un contenu :
  /// l'utilisateur garde la main sur chaque publication.
  final bool isAnonymousByDefault;

  /// Indique si l'échange avec les téléphones proches est activé.
  ///
  /// Enregistré pour que l'échange reprenne tout seul au lancement suivant de l'app.
  final bool isExchangeEnabled;

  /// Retourne une copie de ces settings avec les champs fournis modifiés.
  ///
  /// - [blockedUrls] : nouvelle liste des URLs bloquées.
  /// - [blockedWords] : nouvelle liste des mots bloqués.
  /// - [isAnonymousByDefault] : nouvelle valeur de publication anonyme par défaut.
  /// - [isExchangeEnabled] : nouvelle valeur d'activation de l'échange.
  UserSettings copyWith({
    List<String>? blockedUrls,
    List<String>? blockedWords,
    bool? isAnonymousByDefault,
    bool? isExchangeEnabled,
  }) {
    return UserSettings(
      blockedUrls: blockedUrls ?? this.blockedUrls,
      blockedWords: blockedWords ?? this.blockedWords,
      isAnonymousByDefault: isAnonymousByDefault ?? this.isAnonymousByDefault,
      isExchangeEnabled: isExchangeEnabled ?? this.isExchangeEnabled,
    );
  }
}
