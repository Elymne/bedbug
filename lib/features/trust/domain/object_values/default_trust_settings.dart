import 'package:bedbug/features/trust/domain/object_values/domain_rule.dart';
import 'package:bedbug/features/trust/domain/object_values/trust_settings.dart';
import 'package:bedbug/features/trust/domain/object_values/url_trust_policy.dart';

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
