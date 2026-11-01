import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/screens/exchange_logs/exchange_logs_notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/widgets/headers/app_page_header.dart';
import 'package:bedbug/features/exchange/domain/entities/exchange_log.dart';
import 'package:bedbug/features/exchange/domain/enums/exchange_log_outcome.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Page de debug : une carte par rencontre avec un pair, de la plus récente à la plus ancienne.
class ExchangeLogsScreen extends ConsumerWidget {
  /// Crée un [ExchangeLogsScreen].
  const ExchangeLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;
    final exchangeLogsNotifierWatcher = ref.watch(exchangeLogsNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(title: l10n.exchangeLogsTitle, onBack: context.pop),
            Expanded(
              child: exchangeLogsNotifierWatcher.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(child: Text(l10n.homeGetContentsUnknown)),
                data: (state) {
                  if (state.failureMessage != null) {
                    return Center(child: Text(state.failureMessage!));
                  }
                  if (state.logs.isEmpty) {
                    return Center(child: Text(l10n.exchangeLogsEmpty));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppValues.baseMargin),
                    itemCount: state.logs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _buildLog(context, state.logs[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Carte d'une rencontre.
  ///
  /// - [context] : contexte de la page.
  /// - [log] : rencontre affichée.
  Widget _buildLog(BuildContext context, ExchangeLog log) {
    final l10n = context.loc;
    final materialLocalizations = MaterialLocalizations.of(context);
    final date = materialLocalizations.formatShortDate(log.createdAt);
    final time = TimeOfDay.fromDateTime(log.createdAt);
    final isInitiator = log.isInitiator;
    final awaitedFrame = log.awaitedFrame;
    final isSuccess = log.outcome == ExchangeLogOutcome.success;
    final isDelayed = log.outcome == ExchangeLogOutcome.peerDelayed;

    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.all(Radius.circular(12))),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Text(
              _outcomeLabel(l10n, log.outcome),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isSuccess
                    ? AppColors.onLight
                    : isDelayed
                    ? AppColors.disabled
                    : AppColors.failure,
              ),
            ),
            _buildDetail('$date  ${materialLocalizations.formatTimeOfDay(time, alwaysUse24HourFormat: true)}'),
            _buildDetail(l10n.exchangeLogsPeer(log.peerAddress)),
            if (isInitiator != null)
              _buildDetail(isInitiator ? l10n.exchangeLogsInitiator : l10n.exchangeLogsResponder),
            if (awaitedFrame != null) ...[
              _buildDetail(l10n.exchangeLogsDuration((log.duration.inMilliseconds / 1000).toStringAsFixed(1))),
              if (!isSuccess) _buildDetail(l10n.exchangeLogsAwaitedFrame(awaitedFrame.name)),
              _buildDetail(l10n.exchangeLogsBytes(log.sentBytes, log.receivedBytes)),
              _buildDetail(l10n.exchangeLogsContents(log.importedContents, log.rejectedContents)),
              _buildDetail(l10n.exchangeLogsReactions(log.importedReactions, log.rejectedReactions)),
            ],
            if (log.removedContents > 0) _buildDetail(l10n.exchangeLogsRemoved(log.removedContents)),
          ],
        ),
      ),
    );
  }

  /// Ligne de détail d'une carte.
  ///
  /// - [text] : texte de la ligne.
  Widget _buildDetail(String text) {
    return Text(text, style: const TextStyle(fontSize: 13, color: AppColors.onLight));
  }

  /// Libellé de l'issue [outcome].
  ///
  /// - [l10n] : textes traduits.
  /// - [outcome] : issue de la rencontre.
  String _outcomeLabel(AppLocalizations l10n, ExchangeLogOutcome outcome) {
    return switch (outcome) {
      ExchangeLogOutcome.success => l10n.exchangeLogsOutcomeSuccess,
      ExchangeLogOutcome.incompatibleVersion => l10n.exchangeLogsOutcomeIncompatibleVersion,
      ExchangeLogOutcome.protocolViolation => l10n.exchangeLogsOutcomeProtocolViolation,
      ExchangeLogOutcome.localError => l10n.exchangeLogsOutcomeLocalError,
      ExchangeLogOutcome.peerError => l10n.exchangeLogsOutcomePeerError,
      ExchangeLogOutcome.transportClosed => l10n.exchangeLogsOutcomeTransportClosed,
      ExchangeLogOutcome.timeout => l10n.exchangeLogsOutcomeTimeout,
      ExchangeLogOutcome.cancelled => l10n.exchangeLogsOutcomeCancelled,
      ExchangeLogOutcome.connectionFailed => l10n.exchangeLogsOutcomeConnectionFailed,
      ExchangeLogOutcome.peerDelayed => l10n.exchangeLogsOutcomePeerDelayed,
    };
  }
}
