import 'package:bedbug/core/domain/value_object.dart';
import 'package:bedbug/resources/content/domain_rule/domain_rule.value_object.dart';

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
