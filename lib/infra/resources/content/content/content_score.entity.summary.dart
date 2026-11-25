import 'package:bedbug/infra/resources/content/content/content.entity.dart';
import 'package:bedbug/infra/resources/content/content/content_origin.enum.dart';

/// Résumé d'un [Content] réduit à ce dont dépendent ses scores : sa provenance, son âge, ses rebonds et ses scores
/// actuels.
///
/// Les scores de diffusion, de survie et d'affichage sont recalculés périodiquement pour tous les contenus : relire
/// chaque contenu en entier (corps, médias, dessins) pour n'en utiliser que quatre champs coûterait une lecture de
/// toute la base à chaque recalcul. Le repository ne lit donc que ces colonnes.
///
/// Lecture seule : construit uniquement par les implémentations de repository.
class ContentScoreSummary {
  /// Crée un [ContentScoreSummary].
  ///
  /// - [contentId] : identifiant du contenu résumé.
  /// - [origin] : provenance du contenu, qui fixe la demi-vie de ses scores.
  /// - [createdAt] : date de création du contenu par son auteur, point de départ de la décroissance.
  /// - [bounce] : nombre de rebonds du contenu entre pairs.
  /// - [broadcastScore] : score de diffusion actuellement stocké.
  /// - [survivalScore] : score de survie actuellement stocké.
  /// - [displayScore] : score d'affichage actuellement stocké.
  const ContentScoreSummary({
    required this.contentId,
    required this.origin,
    required this.createdAt,
    required this.bounce,
    required this.broadcastScore,
    required this.survivalScore,
    required this.displayScore,
  });

  /// Identifiant du contenu résumé.
  final String contentId;

  /// Provenance du contenu, qui fixe la demi-vie de ses scores.
  final ContentOrigin origin;

  /// Date de création du contenu par son auteur, point de départ de la décroissance.
  final DateTime createdAt;

  /// Nombre de rebonds du contenu entre pairs.
  final int bounce;

  /// Score de diffusion actuellement stocké.
  final double broadcastScore;

  /// Score de survie actuellement stocké.
  final double survivalScore;

  /// Score d'affichage actuellement stocké.
  final double displayScore;

  /// Deux résumés sont égaux quand ils décrivent le même contenu dans le même état.
  ///
  /// - [other] : objet comparé.
  @override
  bool operator ==(Object other) {
    return other is ContentScoreSummary &&
        other.contentId == contentId &&
        other.origin == origin &&
        other.createdAt == createdAt &&
        other.bounce == bounce &&
        other.broadcastScore == broadcastScore &&
        other.survivalScore == survivalScore &&
        other.displayScore == displayScore;
  }

  /// Empreinte cohérente avec [operator ==].
  @override
  int get hashCode {
    return Object.hash(contentId, origin, createdAt, bounce, broadcastScore, survivalScore, displayScore);
  }

  /// Représentation lisible, pour les journaux et les tests.
  @override
  String toString() {
    return 'ContentScoreSummary($contentId, $origin, $createdAt, $bounce rebonds, '
        'diffusion : $broadcastScore, survie : $survivalScore, affichage : $displayScore)';
  }
}
