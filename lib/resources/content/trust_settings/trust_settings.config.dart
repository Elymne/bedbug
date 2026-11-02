import 'package:bedbug/resources/content/domain_rule/domain_rule.value_object.dart';
import 'package:bedbug/resources/content/trust_settings/trust_settings.value_object.dart';

/// Nom de la box Hive des réglages de confiance.
const String trustSettingsBoxName = 'trust_settings';

/// Réglages de confiance d'un utilisateur qui n'a encore rien modifié.
///
/// Listes provisoires, à revoir avant la préprod : elles couvrent surtout
/// les sources du seeder (placeholders, vidéos de test) pour pouvoir juger
/// du rendu. Les greylists sont vides : c'est à chaque utilisateur d'y ajouter
/// les domaines dont il accepte le risque.
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
    greyRules: [],
  ),
  linkPolicy: UrlTrustPolicy(
    trustedRules: [
      DomainRule(host: 'wikipedia.org', isIncludingSubdomains: true),
      DomainRule(host: 'youtube.com', isIncludingSubdomains: true),
      DomainRule(host: 'youtu.be', isIncludingSubdomains: false),
      DomainRule(host: 'github.com', isIncludingSubdomains: false),
    ],
    greyRules: [],
  ),
);
