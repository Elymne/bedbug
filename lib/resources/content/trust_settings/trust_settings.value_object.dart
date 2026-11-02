import 'package:bedbug/core/domain/value_object.dart';
import 'package:bedbug/resources/url/safe_url/safe_url.value_object.dart';

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

  /// Indique si un contenu pointant vers ces URLs doit disparaître du fil.
  ///
  /// Il suffit d'une seule URL piégée ([UrlTrust.invalid]) ou visant un domaine absent des listes
  /// ([UrlTrust.unknown]) : seuls les domaines choisis par l'utilisateur ont leur place sur son téléphone.
  ///
  /// - [settings] : réglages de confiance de l'utilisateur.
  /// - [mediaUrls] : URLs des médias du contenu.
  /// - [linkUrls] : URLs des liens du contenu.
  static bool isContentHidden(
    TrustSettings settings, {
    List<String> mediaUrls = const [],
    List<String> linkUrls = const [],
  }) {
    final trusts = [
      for (final url in mediaUrls) UrlTrustPolicy.evaluate(settings.mediaPolicy, url),
      for (final url in linkUrls) UrlTrustPolicy.evaluate(settings.linkPolicy, url),
    ];
    return trusts.contains(UrlTrust.invalid) || trusts.contains(UrlTrust.unknown);
  }

  /// Retourne la politique de [family] dans [settings].
  ///
  /// - [settings] : réglages de confiance.
  /// - [family] : famille d'URLs concernée.
  static UrlTrustPolicy policyOf(TrustSettings settings, UrlFamily family) {
    return switch (family) {
      UrlFamily.media => settings.mediaPolicy,
      UrlFamily.link => settings.linkPolicy,
    };
  }

  /// Retourne une copie de [settings] où [rule] est rangée dans la liste [level] de [family].
  ///
  /// Une règle n'appartient qu'à une seule liste à la fois : la ranger dans l'une la retire de l'autre, pour qu'aucune
  /// modification ne laisse un domaine à la fois en whitelist et en greylist. Sert donc aussi à faire passer une règle
  /// d'une liste à l'autre. Une règle déjà présente n'est pas dupliquée.
  ///
  /// - [settings] : réglages de confiance.
  /// - [family] : famille d'URLs concernée.
  /// - [level] : liste de destination.
  /// - [rule] : règle à ranger.
  static TrustSettings withRule(TrustSettings settings, UrlFamily family, TrustLevel level, DomainRule rule) {
    final policy = policyOf(settings, family);
    final trustedRules = [...policy.trustedRules.where((existing) => existing != rule)];
    final greyRules = [...policy.greyRules.where((existing) => existing != rule)];
    switch (level) {
      case TrustLevel.trusted:
        trustedRules.add(rule);
      case TrustLevel.grey:
        greyRules.add(rule);
    }
    return _withPolicy(settings, family, UrlTrustPolicy(trustedRules: trustedRules, greyRules: greyRules));
  }

  /// Retourne une copie de [settings] sans [rule] dans les listes de [family].
  ///
  /// - [settings] : réglages de confiance.
  /// - [family] : famille d'URLs concernée.
  /// - [rule] : règle à retirer.
  static TrustSettings withoutRule(TrustSettings settings, UrlFamily family, DomainRule rule) {
    final policy = policyOf(settings, family);
    return _withPolicy(
      settings,
      family,
      UrlTrustPolicy(
        trustedRules: [...policy.trustedRules.where((existing) => existing != rule)],
        greyRules: [...policy.greyRules.where((existing) => existing != rule)],
      ),
    );
  }

  /// Retourne une copie de [settings] où la politique de [family] est remplacée par [policy].
  ///
  /// - [settings] : réglages de confiance.
  /// - [family] : famille d'URLs concernée.
  /// - [policy] : nouvelle politique.
  static TrustSettings _withPolicy(TrustSettings settings, UrlFamily family, UrlTrustPolicy policy) {
    return switch (family) {
      UrlFamily.media => settings.copyWith(mediaPolicy: policy),
      UrlFamily.link => settings.copyWith(linkPolicy: policy),
    };
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

/// Politique de confiance appliquée à une famille d'URLs (médias ou liens) : une whitelist et une greylist.
///
/// Les médias se chargent sans action de l'utilisateur, et le serveur qui
/// les héberge voit alors son adresse IP : on ne charge donc d'office que
/// ce qui vient de domaines connus. La greylist couvre les domaines
/// acceptés mais qui demandent toujours un geste de l'utilisateur.
class UrlTrustPolicy {
  /// Crée une [UrlTrustPolicy].
  ///
  /// - [trustedRules] : domaines affichés ou ouverts directement.
  /// - [greyRules] : domaines acceptés, mais seulement après une action de l'utilisateur.
  const UrlTrustPolicy({required this.trustedRules, required this.greyRules});

  /// Domaines affichés ou ouverts directement.
  final List<DomainRule> trustedRules;

  /// Domaines acceptés, mais seulement après une action de l'utilisateur.
  final List<DomainRule> greyRules;

  /// Retourne le niveau de confiance de [rawUrl] selon [policy].
  ///
  /// C'est ici, et seulement ici, que les listes sont confrontées aux URLs reçues. Une URL refusée par
  /// [SafeUrl.parse] est [UrlTrust.invalid], quelle que soit la liste : elle ne doit jamais être chargée. Un domaine
  /// présent dans les deux listes est traité comme [UrlTrust.grey] : en cas de doute, la règle la plus prudente
  /// l'emporte.
  ///
  /// - [policy] : politique de confiance à appliquer.
  /// - [rawUrl] : URL telle que reçue, non vérifiée.
  static UrlTrust evaluate(UrlTrustPolicy policy, String rawUrl) {
    final url = SafeUrl.parse(rawUrl);
    if (url == null) {
      return UrlTrust.invalid;
    }
    if (policy.greyRules.any((rule) => DomainRule.matches(rule, url))) {
      return UrlTrust.grey;
    }
    if (policy.trustedRules.any((rule) => DomainRule.matches(rule, url))) {
      return UrlTrust.trusted;
    }
    return UrlTrust.unknown;
  }
}

/// Niveau de confiance d'une URL selon une [UrlTrustPolicy] (voir [UrlTrustPolicy.evaluate]).
enum UrlTrust {
  /// URL piégée ou mal formée : à ne jamais charger ni ouvrir.
  invalid,

  /// Domaine de la whitelist : affiché ou ouvert directement.
  trusted,

  /// Domaine de la greylist : flouté, affiché seulement après confirmation de l'utilisateur.
  grey,

  /// Domaine absent des deux listes : traité selon le réglage de l'utilisateur (masqué, ou flouté).
  unknown,
}

/// Règle d'une liste de domaines : un domaine, avec ou sans ses sous-domaines.
///
/// La comparaison se fait label par label, jamais sur un simple « se termine par » : `evilimgur.com` n'est pas un
/// sous-domaine d'`imgur.com`, et `imgur.com.evil.com` encore moins.
class DomainRule {
  /// Crée une [DomainRule].
  ///
  /// - [host] : nom de domaine, déjà validé et en minuscules (voir [DomainRule.parse]).
  /// - [isIncludingSubdomains] : `true` pour couvrir aussi tous les sous-domaines de [host].
  const DomainRule({required this.host, required this.isIncludingSubdomains});

  /// Nom de domaine couvert, en minuscules.
  final String host;

  /// Indique si la règle couvre aussi les sous-domaines de [host].
  ///
  /// `*.imgur.com` couvre `imgur.com` lui-même et tous ses sous-domaines.
  final bool isIncludingSubdomains;

  /// Caractères autorisés dans une règle, avant mise en minuscules.
  ///
  /// Vérifié avant `toLowerCase` : certains caractères Unicode deviennent des lettres ASCII en minuscules (le signe
  /// kelvin `K` devient `k`), ce qui ferait passer une règle piégée pour une règle ordinaire.
  static final RegExp _ruleCharacters = RegExp(r'^[A-Za-z0-9.*\-]+$');

  /// Préfixe d'une règle qui couvre aussi les sous-domaines.
  static const String _subdomainsPrefix = '*.';

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
    return 'DomainRule($host, isIncludingSubdomains: $isIncludingSubdomains)';
  }

  /// Retourne la règle écrite [pattern], ou `null` si elle n'est pas valide.
  ///
  /// Accepte un domaine (`i.imgur.com`) ou un domaine avec ses sous-domaines (`*.imgur.com`). Les noms
  /// internationalisés doivent être écrits en punycode : leur forme Unicode est justement celle qui permet d'imiter un
  /// domaine.
  ///
  /// Ne vérifie pas que le domaine est un suffixe public (`co.uk`, `github.io`) : c'est le rôle du use case d'ajout
  /// d'une règle, qui a accès à la liste des suffixes publics.
  ///
  /// - [pattern] : règle écrite, sans espaces autour.
  static DomainRule? parse(String pattern) {
    if (!_ruleCharacters.hasMatch(pattern)) {
      return null;
    }
    var host = pattern.toLowerCase();
    final isIncludingSubdomains = host.startsWith(_subdomainsPrefix);
    if (isIncludingSubdomains) {
      host = host.substring(_subdomainsPrefix.length);
    }
    if (!SafeUrl.isValidHostName(host)) {
      return null;
    }
    return DomainRule(host: host, isIncludingSubdomains: isIncludingSubdomains);
  }

  /// Retourne [rule] telle qu'affichée et stockée : `imgur.com`, ou `*.imgur.com` avec les sous-domaines.
  ///
  /// - [rule] : règle à écrire.
  static String patternOf(DomainRule rule) {
    return rule.isIncludingSubdomains ? '$_subdomainsPrefix${rule.host}' : rule.host;
  }

  /// Indique si [url] pointe vers un domaine couvert par [rule].
  ///
  /// - [rule] : règle à appliquer.
  /// - [url] : URL déjà vérifiée.
  static bool matches(DomainRule rule, SafeUrl url) {
    if (url.host == rule.host) {
      return true;
    }
    // Le point fait la frontière entre deux labels : `xa.imgur.com` ne passe
    // pas pour un sous-domaine de `a.imgur.com`.
    return rule.isIncludingSubdomains && url.host.endsWith('.${rule.host}');
  }
}
