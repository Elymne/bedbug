import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/icons/app_bounce_icon.widget.dart';
import 'package:bedbug/application/widgets/icons/app_burst_icon.widget.dart';
import 'package:bedbug/application/widgets/stats/app_stat.widget.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Statistiques d'un contenu : son nombre de rebonds, puis son nombre de réactions.
///
/// Affichées en tête de la ligne des tags, sur les tuiles du fil comme sur la page de détail. Le nombre de réactions
/// est fourni par l'appelant, qui l'a lu avec le contenu (liste) ou avec ses réactions (détail) : aucune lecture par
/// tuile. Il n'apparaît qu'une fois connu, plutôt qu'un zéro qui changerait aussitôt.
class ContentStats extends ConsumerWidget {
  /// Crée des [ContentStats].
  ///
  /// - [bounce] : nombre de rebonds du contenu.
  /// - [reactionCount] : nombre de réactions du contenu, `null` tant qu'il n'est pas connu.
  const ContentStats({super.key, required this.bounce, required this.reactionCount});

  /// Nombre de rebonds du contenu.
  final int bounce;

  /// Nombre de réactions du contenu, `null` tant qu'il n'est pas connu.
  final int? reactionCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;
    final reactionCount = this.reactionCount;

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
