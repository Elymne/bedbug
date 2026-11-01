import 'package:bedbug/features/content/domain/object_values/trust_settings.dart';
import 'package:bedbug/features/content/domain/object_values/url_trust_policy.dart';
import 'package:bedbug/features/content/domain/services/domain_rule_service.dart';
import 'package:bedbug/features/content/domain/services/url_safety_service.dart';
import 'package:bedbug/shared/domain/service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [UrlTrustService].
final urlTrustServiceProvider = Provider<UrlTrustService>((ref) {
  return UrlTrustService(ref.read(urlSafetyServiceProvider), ref.read(domainRuleServiceProvider));
});

/// Décide du niveau de confiance d'une URL, et du sort d'un contenu, selon les listes de l'utilisateur.
///
/// Les médias se chargent sans action de l'utilisateur, et le serveur qui
/// les héberge voit alors son adresse IP : on ne charge donc d'office que
/// ce qui vient de domaines connus. C'est ici, et seulement ici, que les
/// listes sont confrontées aux URLs reçues.
class UrlTrustService extends Service {
  /// Crée un [UrlTrustService].
  const UrlTrustService(this._urlSafetyService, this._domainRuleService);

  final UrlSafetyService _urlSafetyService;

  final DomainRuleService _domainRuleService;

  /// Retourne le niveau de confiance de [rawUrl] selon [policy].
  ///
  /// Une URL refusée par [UrlSafetyService.parse] est [UrlTrust.invalid],
  /// quelle que soit la liste : elle ne doit jamais être chargée. Un domaine
  /// présent dans les deux listes est traité comme [UrlTrust.grey] : en cas
  /// de doute, la règle la plus prudente l'emporte.
  ///
  /// - [policy] : politique de confiance à appliquer.
  /// - [rawUrl] : URL telle que reçue, non vérifiée.
  UrlTrust evaluate(UrlTrustPolicy policy, String rawUrl) {
    final url = _urlSafetyService.parse(rawUrl);
    if (url == null) {
      return UrlTrust.invalid;
    }
    if (policy.greyRules.any((rule) => _domainRuleService.matches(rule, url))) {
      return UrlTrust.grey;
    }
    if (policy.trustedRules.any((rule) => _domainRuleService.matches(rule, url))) {
      return UrlTrust.trusted;
    }
    return UrlTrust.unknown;
  }

  /// Indique si un contenu pointant vers ces URLs doit disparaître du fil.
  ///
  /// Il suffit d'une seule URL piégée ([UrlTrust.invalid]) ou visant un domaine absent des listes
  /// ([UrlTrust.unknown]) : seuls les domaines choisis par l'utilisateur ont leur place sur son téléphone.
  ///
  /// - [settings] : réglages de confiance de l'utilisateur.
  /// - [mediaUrls] : URLs des médias du contenu.
  /// - [linkUrls] : URLs des liens du contenu.
  bool isContentHidden(TrustSettings settings, {List<String> mediaUrls = const [], List<String> linkUrls = const []}) {
    final trusts = [
      for (final url in mediaUrls) evaluate(settings.mediaPolicy, url),
      for (final url in linkUrls) evaluate(settings.linkPolicy, url),
    ];
    return trusts.contains(UrlTrust.invalid) || trusts.contains(UrlTrust.unknown);
  }
}
