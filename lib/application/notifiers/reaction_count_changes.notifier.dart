import 'package:bedbug/infra/resources/content/content/content.entity.detailed.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [ReactionCountChangesNotifier].
final reactionCountChangesNotifierProvider = NotifierProvider<ReactionCountChangesNotifier, List<ReactionCountChange>>(
  ReactionCountChangesNotifier.new,
);

/// Notifier diffusant les nouveaux nombres de réactions des contenus auxquels l'utilisateur vient de réagir.
///
/// Les listes de contenus (fil d'accueil, résultats de recherche) lisent le nombre de réactions de chaque contenu
/// avec le contenu lui-même, en une seule lecture. Quand l'utilisateur réagit depuis la page de détail, la liste
/// restée en dessous doit afficher le nouveau nombre sans tout relire : elle écoute ce notifier et corrige le seul
/// contenu concerné.
///
/// L'état est un journal qui ne fait que s'allonger, et non le dernier changement seul : une liste en pause (écran
/// caché sous un autre) ne reçoit à son retour que la dernière notification, et doit pourtant appliquer chaque
/// changement survenu entre-temps. Chaque liste retient donc combien d'entrées elle a déjà appliquées. Le journal
/// reste minuscule : une entrée par réaction enregistrée pendant la session.
class ReactionCountChangesNotifier extends Notifier<List<ReactionCountChange>> {
  /// Journal vide au lancement de l'application.
  @override
  List<ReactionCountChange> build() {
    return const [];
  }

  /// Ajoute au journal le nouveau nombre de réactions [reactionCount] du contenu [contentId].
  ///
  /// - [contentId] : identifiant du contenu auquel l'utilisateur a réagi.
  /// - [reactionCount] : nombre de réactions stockées sur ce contenu après la réaction.
  void publish({required String contentId, required int reactionCount}) {
    state = [...state, ReactionCountChange(contentId: contentId, reactionCount: reactionCount)];
  }

  /// Retourne [contents] avec les nombres de réactions des [changes] appliqués.
  ///
  /// Partagé par les listes qui écoutent ce notifier : seuls les contenus concernés changent de nombre, les autres
  /// gardent le leur. Quand un contenu apparaît plusieurs fois dans [changes], le plus récent l'emporte.
  ///
  /// - [contents] : contenus affichés par la liste.
  /// - [changes] : changements pas encore appliqués à cette liste, du plus ancien au plus récent.
  static List<ContentDetailed> apply(List<ContentDetailed> contents, Iterable<ReactionCountChange> changes) {
    final reactionCounts = {for (final change in changes) change.contentId: change.reactionCount};
    return [for (final detailed in contents) detailed.copyWith(reactionCount: reactionCounts[detailed.content.id])];
  }
}

/// Nouveau nombre de réactions d'un contenu, après une réaction de l'utilisateur.
class ReactionCountChange {
  /// Crée un [ReactionCountChange].
  ///
  /// - [contentId] : identifiant du contenu auquel l'utilisateur a réagi.
  /// - [reactionCount] : nombre de réactions stockées sur ce contenu après la réaction.
  const ReactionCountChange({required this.contentId, required this.reactionCount});

  /// Identifiant du contenu auquel l'utilisateur a réagi.
  final String contentId;

  /// Nombre de réactions stockées sur ce contenu après la réaction.
  final int reactionCount;
}
