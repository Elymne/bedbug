import 'package:bedbug/core/domain/value_object.dart';
import 'package:bedbug/resources/content/url_trust_policy/url_trust_policy.value_object.dart';

/// Réglages de confiance de l'utilisateur : quels domaines l'app peut contacter, et comment.
///
/// Les médias et les liens ont chacun leur politique : un média s'affiche
/// tout seul (le serveur qui l'héberge voit alors l'adresse IP du
/// téléphone), alors qu'un lien ne s'ouvre que sur un tap. L'utilisateur
/// garde la main sur les deux listes de chaque politique. Un contenu reçu
/// qui pointe vers un domaine classé nulle part est supprimé.
class TrustSettings extends ValueObject {
  /// Crée des [TrustSettings].
  ///
  /// - [mediaPolicy] : domaines des images, gifs, vidéos et aperçus de liens.
  /// - [linkPolicy] : domaines des liens partagés.
  const TrustSettings({required this.mediaPolicy, required this.linkPolicy});

  /// Domaines des images, gifs, vidéos et aperçus de liens.
  final UrlTrustPolicy mediaPolicy;

  /// Domaines des liens partagés.
  final UrlTrustPolicy linkPolicy;

  /// Retourne une copie de ces réglages avec les champs fournis modifiés.
  ///
  /// - [mediaPolicy] : nouvelle politique des médias.
  /// - [linkPolicy] : nouvelle politique des liens.
  TrustSettings copyWith({UrlTrustPolicy? mediaPolicy, UrlTrustPolicy? linkPolicy}) {
    return TrustSettings(mediaPolicy: mediaPolicy ?? this.mediaPolicy, linkPolicy: linkPolicy ?? this.linkPolicy);
  }
}

/// Famille d'URLs, chacune soumise à sa propre politique de confiance.
enum UrlFamily {
  /// Images, gifs, vidéos et aperçus de liens : chargés sans action de l'utilisateur.
  media,

  /// Liens partagés : ouverts seulement sur un tap.
  link,
}

/// Liste dans laquelle ranger une règle.
enum TrustLevel {
  /// Whitelist : affiché ou ouvert directement.
  trusted,

  /// Greylist : flouté, affiché ou ouvert sur confirmation.
  grey,
}
