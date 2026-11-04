import 'package:bedbug/application/screens/settings/exchange_stats_section/exchange_stats_section.notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/separators/app_list_separator.widget.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Statistiques des échanges depuis le lancement de l'app : une ligne par compteur, sa valeur à droite.
///
/// Permet de vérifier d'un coup d'œil que le transfert fonctionne, sans encombrer la page d'échange. Les compteurs
/// se mettent à jour pendant que la page est ouverte.
class ExchangeStatsSection extends ConsumerWidget {
  /// Crée un [ExchangeStatsSection].
  const ExchangeStatsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;
    final exchangeStats = ref.watch(exchangeStatsSectionNotifierProvider);

    final rows = [
      (l10n.settingsExchangeStatsSuccess, exchangeStats.successCount),
      (l10n.settingsExchangeStatsFailure, exchangeStats.failureCount),
      (l10n.settingsExchangeStatsContents, exchangeStats.contentCount),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, (label, count)) in rows.indexed) ...[
          if (index > 0) const AppListSeparator(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(label, style: const TextStyle(fontSize: 15, color: AppColors.onLight)),
            trailing: Text(
              '$count',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onLight),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(l10n.settingsExchangeStatsHint, style: const TextStyle(fontSize: 13, color: AppColors.onLighter)),
      ],
    );
  }
}
