import 'package:bedbug/infra/resources/content/content/content.entity.dart';
import 'package:bedbug/infra/resources/signature/signature/signature.entity.dart';

/// Un [Content] accompagné de ce qu'une liste affiche autour de lui : son auteur, son nombre de réactions, et s'il a
/// déjà été vu.
///
/// Une liste de contenus (fil d'accueil, recherche, contenus de l'utilisateur, lot envoyé à un pair) a besoin de ces
/// informations pour chaque contenu : les lire contenu par contenu ferait une requête par ligne. Le repository les
/// assemble donc en une seule lecture, par jointure.
///
/// Lecture seule : construit par les implémentations de repository (puis seulement copié), jamais écrit tel quel.
/// Son identité est celle de son [content].
class ContentDetailed {
  /// Crée un [ContentDetailed].
  ///
  /// - [content] : contenu lu.
  /// - [signature] : signature de l'auteur, `null` pour un contenu anonyme ou dont la signature n'est plus connue.
  /// - [reactionCount] : nombre de réactions stockées sur ce contenu.
  /// - [isViewed] : indique si l'utilisateur a déjà eu ce contenu à l'écran.
  const ContentDetailed({
    required this.content,
    required this.signature,
    required this.reactionCount,
    required this.isViewed,
  });

  /// Contenu lu.
  final Content content;

  /// Signature de l'auteur, `null` pour un contenu anonyme ou dont la signature n'est plus connue.
  final Signature? signature;

  /// Nombre de réactions stockées sur ce contenu.
  final int reactionCount;

  /// Indique si l'utilisateur a déjà eu ce contenu à l'écran.
  ///
  /// Dans le fil d'accueil, seules comptent les vues antérieures au début de la session de lecture : un contenu vu
  /// pendant le défilement garde sa place jusqu'au rechargement du fil.
  final bool isViewed;

  /// Retourne [displayed] suivi des éléments de [page] qui n'y figurent pas encore.
  ///
  /// Une liste paginée s'allonge page après page pendant que les scores continuent d'être recalculés : un contenu
  /// déjà affiché peut remonter dans une page suivante. Il garde alors sa première place plutôt que d'apparaître deux
  /// fois.
  ///
  /// - [displayed] : éléments déjà affichés, dans l'ordre de la liste.
  /// - [page] : éléments de la page suivante, dans l'ordre de la liste.
  static List<ContentDetailed> appendPage(List<ContentDetailed> displayed, List<ContentDetailed> page) {
    final displayedIds = {for (final detailed in displayed) detailed.content.id};
    return [
      ...displayed,
      for (final detailed in page)
        if (displayedIds.add(detailed.content.id)) detailed,
    ];
  }

  /// Retourne une copie de cet élément, avec les valeurs fournies à la place des siennes.
  ///
  /// Permet à une liste déjà affichée de refléter un changement (une réaction ajoutée par l'utilisateur) sans relire
  /// toute la liste.
  ///
  /// - [reactionCount] : nouveau nombre de réactions, celui de cet élément si absent.
  ContentDetailed copyWith({int? reactionCount}) {
    return ContentDetailed(
      content: content,
      signature: signature,
      reactionCount: reactionCount ?? this.reactionCount,
      isViewed: isViewed,
    );
  }

  /// Représentation lisible, pour les journaux et les tests.
  @override
  String toString() {
    return 'ContentDetailed(${content.id}, signature: ${signature?.id}, réactions: $reactionCount, vu: $isViewed)';
  }
}
