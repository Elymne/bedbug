import 'package:bedbug/application/exchange/exchange_stats_notifier.dart';
import 'package:bedbug/application/exchange/passive_exchange_notifier.dart';
import 'package:bedbug/application/widgets/headers/app_page_header.dart';
import 'package:bedbug/application/widgets/snackbars/app_snackbar.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Page d'activation de l'échange de contenus avec les téléphones proches.
class ExchangeScreen extends ConsumerWidget {
  /// Crée un [ExchangeScreen].
  const ExchangeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;
    final passiveExchangeNotifierWatcher = ref.watch(passiveExchangeNotifierProvider);
    final exchangeStats = ref.watch(exchangeStatsNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(title: l10n.navExchangeLabel, onBack: context.pop),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 8,
                children: [
                  Text(l10n.exchangeToggleLabel),
                  Checkbox(
                    value: passiveExchangeNotifierWatcher.value ?? false,
                    onChanged: passiveExchangeNotifierWatcher.isLoading
                        ? null
                        : (isChecked) => _onToggle(context, ref, isEnabled: isChecked ?? false),
                  ),
                  Text(
                    l10n.exchangeStats(
                      exchangeStats.successCount,
                      exchangeStats.failureCount,
                      exchangeStats.contentCount,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Active ou coupe l'échange, et affiche l'erreur s'il y en a une.
  ///
  /// - [context] : contexte de la page.
  /// - [ref] : accès aux providers.
  /// - [isEnabled] : `true` pour activer l'échange.
  Future<void> _onToggle(BuildContext context, WidgetRef ref, {required bool isEnabled}) async {
    final failureMessage = await ref.read(passiveExchangeNotifierProvider.notifier).setEnabled(isEnabled: isEnabled);
    if (failureMessage != null && context.mounted) {
      AppSnackbar.showError(context, failureMessage);
    }
  }
}
