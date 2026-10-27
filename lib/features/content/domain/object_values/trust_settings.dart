import 'package:bedbug/features/content/domain/object_values/domain_rule.dart';
import 'package:bedbug/features/content/domain/object_values/url_trust_policy.dart';
import 'package:bedbug/shared/domain/value_object.dart';

/// Réglages de confiance de l'utilisateur : quels domaines l'app peut contacter, et comment.
///
/// Les médias et les liens ont chacun leur politique : un média s'affiche
/// tout seul (le serveur qui l'héberge voit alors l'adresse IP du
/// téléphone), alors qu'un lien ne s'ouvre que sur un tap. L'utilisateur
/// garde la main sur les deux listes de chaque politique, et sur le sort
/// des domaines qu'il n'a classés nulle part.
class TrustSettings extends ValueObject {
  /// Crée des [TrustSettings].
  ///
  /// - [mediaPolicy] : domaines des images, gifs, vidéos et aperçus de liens.
  /// - [linkPolicy] : domaines des liens partagés.
  /// - [unknownDomainBehavior] : sort d'un contenu qui pointe vers un domaine absent des listes.
  const TrustSettings({required this.mediaPolicy, required this.linkPolicy, required this.unknownDomainBehavior});

  /// Domaines des images, gifs, vidéos et aperçus de liens.
  final UrlTrustPolicy mediaPolicy;

  /// Domaines des liens partagés.
  final UrlTrustPolicy linkPolicy;

  /// Sort d'un contenu qui pointe vers un domaine absent des listes.
  final UnknownDomainBehavior unknownDomainBehavior;

  /// Retourne une copie de ces réglages avec les champs fournis modifiés.
  ///
  /// - [mediaPolicy] : nouvelle politique des médias.
  /// - [linkPolicy] : nouvelle politique des liens.
  /// - [unknownDomainBehavior] : nouveau sort des domaines inconnus.
  TrustSettings copyWith({
    UrlTrustPolicy? mediaPolicy,
    UrlTrustPolicy? linkPolicy,
    UnknownDomainBehavior? unknownDomainBehavior,
  }) {
    return TrustSettings(
      mediaPolicy: mediaPolicy ?? this.mediaPolicy,
      linkPolicy: linkPolicy ?? this.linkPolicy,
      unknownDomainBehavior: unknownDomainBehavior ?? this.unknownDomainBehavior,
    );
  }
}

/// Réglages de confiance d'un utilisateur qui n'a encore rien modifié.
///
/// Listes provisoires, à revoir avant la préprod : elles couvrent surtout
/// les sources du seeder (placeholders, vidéos de test) pour pouvoir juger
/// du rendu. Les domaines inconnus sont masqués : rien n'est chargé depuis
/// un site que personne n'a choisi.
const TrustSettings defaultTrustSettings = TrustSettings(
  mediaPolicy: UrlTrustPolicy(
    trustedRules: [
      DomainRule(host: 'upload.wikimedia.org', isIncludingSubdomains: false),
      // `picsum.photos` redirige vers `fastly.picsum.photos` : le domaine et ses
      // sous-domaines doivent être couverts pour que la redirection passe.
      DomainRule(host: 'picsum.photos', isIncludingSubdomains: true),
      DomainRule(host: 'test-videos.co.uk', isIncludingSubdomains: false),
      DomainRule(host: 'i.imgur.com', isIncludingSubdomains: false),
      DomainRule(host: 'media.giphy.com', isIncludingSubdomains: false),
      DomainRule(host: 'i.ytimg.com', isIncludingSubdomains: false),
    ],
    greyRules: [
      DomainRule(host: 'placehold.co', isIncludingSubdomains: false),
      DomainRule(host: 'i.redd.it', isIncludingSubdomains: false),
    ],
  ),
  linkPolicy: UrlTrustPolicy(
    trustedRules: [
      DomainRule(host: 'wikipedia.org', isIncludingSubdomains: true),
      DomainRule(host: 'youtube.com', isIncludingSubdomains: true),
      DomainRule(host: 'youtu.be', isIncludingSubdomains: false),
      DomainRule(host: 'github.com', isIncludingSubdomains: false),
    ],
    greyRules: [DomainRule(host: 'reddit.com', isIncludingSubdomains: true)],
  ),
  unknownDomainBehavior: UnknownDomainBehavior.hidden,
);

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

/// Sort d'un contenu qui pointe vers un domaine absent des listes.
enum UnknownDomainBehavior {
  /// Le contenu disparaît du fil.
  hidden(0),

  /// Le contenu reste, son média n'est pas chargé : il faut confirmer pour l'afficher.
  blurred(1);

  const UnknownDomainBehavior(this.value);

  /// Valeur entière persistée. Stable indépendamment de l'ordre de déclaration.
  final int value;

  /// Retourne le comportement correspondant à [value], ou [hidden] s'il est inconnu.
  ///
  /// Une valeur inconnue peut provenir d'une version plus récente de l'app :
  /// le choix le plus prudent prend alors le relais.
  ///
  /// - [value] : valeur entière persistée.
  static UnknownDomainBehavior fromValue(int value) {
    for (final behavior in UnknownDomainBehavior.values) {
      if (behavior.value == value) {
        return behavior;
      }
    }
    return hidden;
  }
}
