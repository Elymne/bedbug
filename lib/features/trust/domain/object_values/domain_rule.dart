import 'package:bedbug/features/trust/domain/extensions/host_name_extension.dart';
import 'package:bedbug/features/trust/domain/object_values/safe_url.dart';
import 'package:bedbug/shared/domain/value_object.dart';

/// Caractères autorisés dans une règle saisie, avant mise en minuscules.
///
/// Vérifié avant `toLowerCase` : certains caractères Unicode deviennent des
/// lettres ASCII en minuscules (le signe kelvin `K` devient `k`), ce qui
/// ferait passer une règle piégée pour une règle ordinaire.
final RegExp _ruleCharacters = RegExp(r'^[A-Za-z0-9.*\-]+$');

/// Préfixe d'une règle qui couvre aussi les sous-domaines.
const String _subdomainsPrefix = '*.';

/// Règle d'une liste de domaines : un domaine, avec ou sans ses sous-domaines.
///
/// La comparaison se fait label par label, jamais sur un simple « se
/// termine par » : `evilimgur.com` n'est pas un sous-domaine d'`imgur.com`,
/// et `imgur.com.evil.com` encore moins.
class DomainRule extends ValueObject {
  /// Crée une [DomainRule].
  ///
  /// - [host] : nom de domaine, déjà validé et en minuscules (voir [tryParse]).
  /// - [isIncludingSubdomains] : `true` pour couvrir aussi tous les sous-domaines de [host].
  const DomainRule({required this.host, required this.isIncludingSubdomains});

  /// Nom de domaine couvert, en minuscules.
  final String host;

  /// Indique si la règle couvre aussi les sous-domaines de [host].
  ///
  /// `*.imgur.com` couvre `imgur.com` lui-même et tous ses sous-domaines.
  final bool isIncludingSubdomains;

  /// Règle telle qu'affichée et saisie : `imgur.com`, ou `*.imgur.com` avec les sous-domaines.
  String get pattern {
    return isIncludingSubdomains ? '$_subdomainsPrefix$host' : host;
  }

  /// Retourne la règle correspondant à [input], ou `null` si elle n'est pas valide.
  ///
  /// Accepte un domaine (`i.imgur.com`), un domaine avec ses sous-domaines
  /// (`*.imgur.com`), ou une URL complète, dont seul le domaine est gardé
  /// (un utilisateur colle plus volontiers une URL qu'il ne tape un
  /// domaine). Les noms internationalisés doivent être saisis en punycode :
  /// leur forme Unicode est justement celle qui permet d'imiter un domaine.
  ///
  /// Ne vérifie pas que le domaine est un suffixe public (`co.uk`,
  /// `github.io`) : c'est le rôle du use case d'ajout d'une règle, qui a
  /// accès à la liste des suffixes publics.
  ///
  /// - [input] : saisie de l'utilisateur.
  static DomainRule? tryParse(String input) {
    final trimmed = input.trim();
    if (trimmed.contains('://')) {
      final url = SafeUrl.tryParse(trimmed);
      if (url == null) {
        return null;
      }
      return DomainRule(host: url.host, isIncludingSubdomains: false);
    }

    if (!_ruleCharacters.hasMatch(trimmed)) {
      return null;
    }
    var host = trimmed.toLowerCase();
    final isIncludingSubdomains = host.startsWith(_subdomainsPrefix);
    if (isIncludingSubdomains) {
      host = host.substring(_subdomainsPrefix.length);
    }
    if (!host.isValidHostName) {
      return null;
    }
    return DomainRule(host: host, isIncludingSubdomains: isIncludingSubdomains);
  }

  /// Indique si [url] pointe vers un domaine couvert par cette règle.
  ///
  /// - [url] : URL déjà vérifiée.
  bool matches(SafeUrl url) {
    if (url.host == host) {
      return true;
    }
    // Le point fait la frontière entre deux labels : `xa.imgur.com` ne passe
    // pas pour un sous-domaine de `a.imgur.com`.
    return isIncludingSubdomains && url.host.endsWith('.$host');
  }

  @override
  bool operator ==(Object other) {
    return other is DomainRule && other.host == host && other.isIncludingSubdomains == isIncludingSubdomains;
  }

  @override
  int get hashCode {
    return Object.hash(host, isIncludingSubdomains);
  }

  @override
  String toString() {
    return pattern;
  }
}
