import 'package:bedbug/features/content/domain/object_values/domain_rule.dart';
import 'package:bedbug/features/content/domain/object_values/trust_settings.dart';
import 'package:bedbug/features/content/domain/object_values/url_trust_policy.dart';
import 'package:bedbug/shared/domain/service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [TrustRulesService].
final trustRulesServiceProvider = Provider<TrustRulesService>((ref) => const TrustRulesService());

/// Range et retire les règles des listes de domaines de l'utilisateur.
///
/// Une règle n'appartient qu'à une seule liste à la fois : la ranger dans
/// l'une la retire de l'autre. Garder cette règle au même endroit évite
/// qu'une modification laisse un domaine à la fois en whitelist et en
/// greylist.
class TrustRulesService extends Service {
  /// Crée un [TrustRulesService].
  const TrustRulesService();

  /// Retourne la politique de [family] dans [settings].
  ///
  /// - [settings] : réglages de confiance.
  /// - [family] : famille d'URLs concernée.
  UrlTrustPolicy policyOf(TrustSettings settings, UrlFamily family) {
    return switch (family) {
      UrlFamily.media => settings.mediaPolicy,
      UrlFamily.link => settings.linkPolicy,
    };
  }

  /// Retourne une copie de [settings] où [rule] est rangée dans la liste [level] de [family].
  ///
  /// Sert aussi à faire passer une règle d'une liste à l'autre. Une règle
  /// déjà présente n'est pas dupliquée.
  ///
  /// - [settings] : réglages de confiance.
  /// - [family] : famille d'URLs concernée.
  /// - [level] : liste de destination.
  /// - [rule] : règle à ranger.
  TrustSettings withRule(TrustSettings settings, UrlFamily family, TrustLevel level, DomainRule rule) {
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
  TrustSettings withoutRule(TrustSettings settings, UrlFamily family, DomainRule rule) {
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
  TrustSettings _withPolicy(TrustSettings settings, UrlFamily family, UrlTrustPolicy policy) {
    return switch (family) {
      UrlFamily.media => settings.copyWith(mediaPolicy: policy),
      UrlFamily.link => settings.copyWith(linkPolicy: policy),
    };
  }
}
