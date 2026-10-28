import 'package:bedbug/features/content/domain/object_values/domain_rule.dart';
import 'package:bedbug/features/content/domain/object_values/safe_url.dart';
import 'package:bedbug/features/content/domain/services/url_safety_service.dart';
import 'package:bedbug/shared/domain/service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Caractères autorisés dans une règle, avant mise en minuscules.
///
/// Vérifié avant `toLowerCase` : certains caractères Unicode deviennent des
/// lettres ASCII en minuscules (le signe kelvin `K` devient `k`), ce qui
/// ferait passer une règle piégée pour une règle ordinaire.
final RegExp _ruleCharacters = RegExp(r'^[A-Za-z0-9.*\-]+$');

/// Préfixe d'une règle qui couvre aussi les sous-domaines.
const String _subdomainsPrefix = '*.';

/// Provider du [DomainRuleService].
final domainRuleServiceProvider = Provider<DomainRuleService>((ref) {
  return DomainRuleService(ref.read(urlSafetyServiceProvider));
});

/// Lit, écrit et applique les règles des listes de domaines.
///
/// La comparaison se fait label par label, jamais sur un simple « se
/// termine par » : `evilimgur.com` n'est pas un sous-domaine d'`imgur.com`,
/// et `imgur.com.evil.com` encore moins.
class DomainRuleService extends Service {
  /// Crée un [DomainRuleService].
  const DomainRuleService(this._urlSafetyService);

  final UrlSafetyService _urlSafetyService;

  /// Retourne la règle écrite [pattern], ou `null` si elle n'est pas valide.
  ///
  /// Accepte un domaine (`i.imgur.com`) ou un domaine avec ses sous-domaines
  /// (`*.imgur.com`). Les noms internationalisés doivent être écrits en
  /// punycode : leur forme Unicode est justement celle qui permet d'imiter
  /// un domaine.
  ///
  /// Ne vérifie pas que le domaine est un suffixe public (`co.uk`,
  /// `github.io`) : c'est le rôle du use case d'ajout d'une règle, qui a
  /// accès à la liste des suffixes publics.
  ///
  /// - [pattern] : règle écrite, sans espaces autour.
  DomainRule? parse(String pattern) {
    if (!_ruleCharacters.hasMatch(pattern)) {
      return null;
    }
    var host = pattern.toLowerCase();
    final isIncludingSubdomains = host.startsWith(_subdomainsPrefix);
    if (isIncludingSubdomains) {
      host = host.substring(_subdomainsPrefix.length);
    }
    if (!_urlSafetyService.isValidHostName(host)) {
      return null;
    }
    return DomainRule(host: host, isIncludingSubdomains: isIncludingSubdomains);
  }

  /// Retourne [rule] telle qu'affichée et stockée : `imgur.com`, ou `*.imgur.com` avec les sous-domaines.
  ///
  /// - [rule] : règle à écrire.
  String patternOf(DomainRule rule) {
    return rule.isIncludingSubdomains ? '$_subdomainsPrefix${rule.host}' : rule.host;
  }

  /// Indique si [url] pointe vers un domaine couvert par [rule].
  ///
  /// - [rule] : règle à appliquer.
  /// - [url] : URL déjà vérifiée.
  bool matches(DomainRule rule, SafeUrl url) {
    if (url.host == rule.host) {
      return true;
    }
    // Le point fait la frontière entre deux labels : `xa.imgur.com` ne passe
    // pas pour un sous-domaine de `a.imgur.com`.
    return rule.isIncludingSubdomains && url.host.endsWith('.${rule.host}');
  }
}
