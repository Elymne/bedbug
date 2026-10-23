import 'package:bedbug/features/signature/domain/enums/social_network.dart';

/// Libellés d'affichage des [SocialNetwork].
///
/// Ce sont des noms de marque, identiques dans toutes les langues : ils ne
/// passent donc pas par les fichiers de traduction.
extension SocialNetworkX on SocialNetwork {
  /// Nom du réseau tel qu'affiché à l'utilisateur.
  String get displayName {
    return switch (this) {
      SocialNetwork.youtube => 'YouTube',
      SocialNetwork.twitter => 'Twitter',
      SocialNetwork.twitch => 'Twitch',
      SocialNetwork.deviantArt => 'DeviantArt',
      SocialNetwork.artStation => 'ArtStation',
      SocialNetwork.pixiv => 'Pixiv',
      SocialNetwork.bluesky => 'Bluesky',
      SocialNetwork.kofi => 'Ko-fi',
      SocialNetwork.onlyFans => 'OnlyFans',
      SocialNetwork.github => 'GitHub',
      SocialNetwork.gitlab => 'GitLab',
      SocialNetwork.linkedin => 'LinkedIn',
    };
  }
}
