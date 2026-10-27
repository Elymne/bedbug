import 'package:bedbug/application/notifiers/content_reaction_count_notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/icons/app_bounce_icon.dart';
import 'package:bedbug/application/widgets/icons/app_burst_icon.dart';
import 'package:bedbug/application/widgets/stats/app_stat.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Statistiques d'un contenu : son nombre de rebonds, puis son nombre de réactions.
///
/// Affichées en tête de la ligne des tags, sur les tuiles du fil comme sur la
/// page de détail. Le nombre de réactions n'apparaît qu'une fois chargé,
/// plutôt qu'un zéro qui changerait aussitôt.
class ContentStats extends ConsumerWidget {
  /// Crée des [ContentStats].
  ///
  /// - [contentId] : identifiant du contenu, pour compter ses réactions.
  /// - [bounce] : nombre de rebonds du contenu.
  const ContentStats({super.key, required this.contentId, required this.bounce});

  /// Identifiant du contenu, pour compter ses réactions.
  final String contentId;

  /// Nombre de rebonds du contenu.
  final int bounce;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;
    final contentReactionCountNotifierWatcher = ref.watch(contentReactionCountNotifierProvider(contentId));
    final reactionCount = contentReactionCountNotifierWatcher.value;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        AppStat(
          icon: const AppBounceIcon(color: AppColors.onLight),
          label: '+$bounce',
          ghostColor: AppColors.primary,
          semanticsLabel: l10n.contentBounceCountLabel(bounce),
        ),
        if (reactionCount != null)
          AppStat(
            icon: const AppBurstIcon(color: AppColors.onLight),
            label: '$reactionCount',
            ghostColor: AppColors.secondary,
            semanticsLabel: l10n.contentReactionCountLabel(reactionCount),
          ),
      ],
    );
  }
}
