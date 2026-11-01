import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/features/exchange/domain/entities/exchange_log.dart';
import 'package:bedbug/features/exchange/domain/usecases/get_exchange_logs_usecase.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/notifier/notifier_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [ExchangeLogsNotifier].
final exchangeLogsNotifierProvider = AsyncNotifierProvider<ExchangeLogsNotifier, ExchangeLogsState>(
  ExchangeLogsNotifier.new,
);

/// Notifier du journal des échanges, rechargé à chaque nouvelle trace.
class ExchangeLogsNotifier extends AsyncNotifier<ExchangeLogsState> {
  /// Cas d'usage de lecture du journal.
  late final _getExchangeLogsUsecase = ref.read(getExchangeLogsUsecaseProvider);

  @override
  Future<ExchangeLogsState> build() async {
    final result = await _getExchangeLogsUsecase(const NoParams());
    return result.fold(
      onFailure: (GetExchangeLogsFailure failure) {
        final message = switch (failure) {
          GetExchangeLogsFailure.invalidData => ref.l10n.homeGetContentsInvalidData,
          GetExchangeLogsFailure.storageError => ref.l10n.homeGetContentsStorageError,
          GetExchangeLogsFailure.unknown => ref.l10n.homeGetContentsUnknown,
        };
        return ExchangeLogsState(logs: const [], failureMessage: message);
      },
      onSuccess: (List<ExchangeLog> logs) => ExchangeLogsState(logs: logs),
    );
  }
}

/// État du journal des échanges.
class ExchangeLogsState extends NotifierState {
  /// Crée un [ExchangeLogsState].
  ///
  /// - [logs] : traces, de la plus récente à la plus ancienne.
  /// - [failureMessage] : message d'erreur éventuel.
  ExchangeLogsState({required this.logs, super.failureMessage});

  /// Traces, de la plus récente à la plus ancienne.
  final List<ExchangeLog> logs;
}
