import 'package:bedbug/features/trust/domain/object_values/domain_rule.dart';
import 'package:bedbug/features/trust/domain/object_values/url_trust_policy.dart';
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

  /// Retourne la politique de [family].
  ///
  /// - [family] : famille d'URLs concernée.
  UrlTrustPolicy policyOf(UrlFamily family) {
    return switch (family) {
      UrlFamily.media => mediaPolicy,
      UrlFamily.link => linkPolicy,
    };
  }

  /// Indique si un contenu pointant vers ces URLs doit disparaître du fil.
  ///
  /// Un contenu est masqué dès qu'une seule de ses URLs est piégée
  /// ([UrlTrust.invalid]), quel que soit le réglage : il ne doit jamais
  /// rien charger. Il l'est aussi dès qu'une URL vise un domaine inconnu,
  /// si l'utilisateur a choisi de masquer ces contenus.
  ///
  /// - [mediaUrls] : URLs des médias du contenu.
  /// - [linkUrls] : URLs des liens du contenu.
  bool isContentHidden({List<String> mediaUrls = const [], List<String> linkUrls = const []}) {
    final trusts = [
      for (final url in mediaUrls) mediaPolicy.evaluate(url),
      for (final url in linkUrls) linkPolicy.evaluate(url),
    ];
    if (trusts.contains(UrlTrust.invalid)) {
      return true;
    }
    return unknownDomainBehavior == UnknownDomainBehavior.hidden && trusts.contains(UrlTrust.unknown);
  }

  /// Retourne une copie où [rule] est rangée dans la liste [level] de [family].
  ///
  /// Une règle n'appartient qu'à une liste à la fois : l'ajouter à l'une la
  /// retire de l'autre, ce qui sert aussi à la faire passer d'une liste à
  /// l'autre. Une règle déjà présente n'est pas dupliquée.
  ///
  /// - [family] : famille d'URLs concernée.
  /// - [level] : liste de destination.
  /// - [rule] : règle à ranger.
  TrustSettings withRule(UrlFamily family, TrustLevel level, DomainRule rule) {
    final policy = policyOf(family);
    final trustedRules = [...policy.trustedRules.where((existing) => existing != rule)];
    final greyRules = [...policy.greyRules.where((existing) => existing != rule)];
    switch (level) {
      case TrustLevel.trusted:
        trustedRules.add(rule);
      case TrustLevel.grey:
        greyRules.add(rule);
    }
    return _withPolicy(family, UrlTrustPolicy(trustedRules: trustedRules, greyRules: greyRules));
  }

  /// Retourne une copie sans [rule] dans les listes de [family].
  ///
  /// - [family] : famille d'URLs concernée.
  /// - [rule] : règle à retirer.
  TrustSettings withoutRule(UrlFamily family, DomainRule rule) {
    final policy = policyOf(family);
    return _withPolicy(
      family,
      UrlTrustPolicy(
        trustedRules: [...policy.trustedRules.where((existing) => existing != rule)],
        greyRules: [...policy.greyRules.where((existing) => existing != rule)],
      ),
    );
  }

  /// Retourne une copie avec [behavior] comme sort des domaines inconnus.
  ///
  /// - [behavior] : nouveau comportement.
  TrustSettings withUnknownDomainBehavior(UnknownDomainBehavior behavior) {
    return TrustSettings(mediaPolicy: mediaPolicy, linkPolicy: linkPolicy, unknownDomainBehavior: behavior);
  }

  /// Retourne une copie où la politique de [family] est remplacée par [policy].
  TrustSettings _withPolicy(UrlFamily family, UrlTrustPolicy policy) {
    return TrustSettings(
      mediaPolicy: family == UrlFamily.media ? policy : mediaPolicy,
      linkPolicy: family == UrlFamily.link ? policy : linkPolicy,
      unknownDomainBehavior: unknownDomainBehavior,
    );
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
