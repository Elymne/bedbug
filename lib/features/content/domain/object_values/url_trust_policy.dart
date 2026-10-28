import 'package:bedbug/features/content/domain/object_values/domain_rule.dart';
import 'package:bedbug/shared/domain/value_object.dart';

/// Politique de confiance appliquée à une famille d'URLs (médias ou liens) : une whitelist et une greylist.
///
/// Les médias se chargent sans action de l'utilisateur, et le serveur qui
/// les héberge voit alors son adresse IP : on ne charge donc d'office que
/// ce qui vient de domaines connus. La greylist couvre les domaines
/// acceptés mais qui demandent toujours un geste de l'utilisateur.
class UrlTrustPolicy extends ValueObject {
  /// Crée une [UrlTrustPolicy].
  ///
  /// - [trustedRules] : domaines affichés ou ouverts directement.
  /// - [greyRules] : domaines acceptés, mais seulement après une action de l'utilisateur.
  const UrlTrustPolicy({required this.trustedRules, required this.greyRules});

  /// Domaines affichés ou ouverts directement.
  final List<DomainRule> trustedRules;

  /// Domaines acceptés, mais seulement après une action de l'utilisateur.
  final List<DomainRule> greyRules;
}

/// Niveau de confiance d'une URL selon une [UrlTrustPolicy] (voir `UrlTrustService.evaluate`).
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
