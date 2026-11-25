import 'package:bedbug/application/screens/content_detail/content_reactions_section/content_reactions_section.notifier.dart';
import 'package:bedbug/application/widgets/stats/content_stats.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Statistiques d'un contenu sur sa page de détail : rebonds et nombre de réactions.
///
/// La page charge déjà toutes les réactions du contenu pour les afficher : leur nombre en découle, sans lecture à
/// part. Il suit aussi la réaction que l'utilisateur vient d'ajouter, puisque l'enregistrement recharge ces
/// réactions.
class ContentDetailStats extends ConsumerWidget {
  /// Crée des [ContentDetailStats].
  ///
  /// - [contentId] : identifiant du contenu, dont les réactions sont comptées.
  /// - [bounce] : nombre de rebonds du contenu.
  const ContentDetailStats({super.key, required this.contentId, required this.bounce});

  /// Identifiant du contenu, dont les réactions sont comptées.
  final String contentId;

  /// Nombre de rebonds du contenu.
  final int bounce;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentReactionsSectionNotifierWatcher = ref.watch(contentReactionsSectionNotifierProvider(contentId));
    final reactionsState = contentReactionsSectionNotifierWatcher.value;
    // Des réactions illisibles ne valent pas zéro : le nombre n'est alors pas affiché.
    final reactionCount = reactionsState?.failureMessage == null ? reactionsState?.reactions.length : null;

    return ContentStats(bounce: bounce, reactionCount: reactionCount);
  }
}
