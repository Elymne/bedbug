import 'package:bedbug/infra/resources/content/content/content.entity.dart';

/// Résumé d'un [Content] : son poids et l'état de ses réactions, sans le contenu lui-même.
///
/// L'offre d'un échange et le choix de ce qu'on demande à un pair ne regardent que ces chiffres, pour des dizaines de
/// contenus à la fois : charger chaque contenu (et ses dessins) puis toutes ses réactions pour les compter coûterait
/// une lecture par contenu. Le repository les calcule en une seule requête groupée.
///
/// Lecture seule : construit uniquement par les implémentations de repository.
class ContentSummary {
  /// Crée un [ContentSummary].
  ///
  /// - [contentId] : identifiant du contenu résumé.
  /// - [sizeInBytes] : poids du contenu, en octets.
  /// - [reactionCount] : nombre de réactions stockées sur ce contenu.
  /// - [latestReactionAt] : date de mise à jour de sa réaction la plus récente, `null` s'il n'en a aucune.
  const ContentSummary({
    required this.contentId,
    required this.sizeInBytes,
    required this.reactionCount,
    required this.latestReactionAt,
  });

  /// Identifiant du contenu résumé.
  final String contentId;

  /// Poids du contenu, en octets.
  final int sizeInBytes;

  /// Nombre de réactions stockées sur ce contenu.
  final int reactionCount;

  /// Date de mise à jour de sa réaction la plus récente, `null` s'il n'en a aucune.
  final DateTime? latestReactionAt;

  /// Deux résumés sont égaux quand ils décrivent le même contenu dans le même état.
  ///
  /// - [other] : objet comparé.
  @override
  bool operator ==(Object other) {
    return other is ContentSummary &&
        other.contentId == contentId &&
        other.sizeInBytes == sizeInBytes &&
        other.reactionCount == reactionCount &&
        other.latestReactionAt == latestReactionAt;
  }

  /// Empreinte cohérente avec [operator ==].
  @override
  int get hashCode {
    return Object.hash(contentId, sizeInBytes, reactionCount, latestReactionAt);
  }

  /// Représentation lisible, pour les journaux et les tests.
  @override
  String toString() {
    return 'ContentSummary($contentId, $sizeInBytes o, $reactionCount réactions, dernière : $latestReactionAt)';
  }
}
