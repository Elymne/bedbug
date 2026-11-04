import 'package:bedbug/application/screens/exchange/exchange_stats/exchange_stats.notifier.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compteurs des échanges depuis le lancement de l'app : réussis, échoués et contenus reçus.
///
/// Permet de voir d'un coup d'œil si le transfert fonctionne ; seul ce texte se reconstruit à chaque échange.
class ExchangeStats extends ConsumerWidget {
  /// Crée un [ExchangeStats].
  const ExchangeStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exchangeStats = ref.watch(exchangeStatsNotifierProvider);

    return Text(
      context.loc.exchangeStats(exchangeStats.successCount, exchangeStats.failureCount, exchangeStats.contentCount),
      textAlign: TextAlign.center,
    );
  }
}
