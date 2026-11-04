import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/core/notifier/notifier_state.dart';
import 'package:bedbug/resources/exchange/exchange_log/exchange_log.entity.dart';
import 'package:bedbug/usecases/exchange/get_exchange_logs/get_exchange_logs.failure.dart';
import 'package:bedbug/usecases/exchange/get_exchange_logs/get_exchange_logs.usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [ExchangeLogsListNotifier].
final exchangeLogsListNotifierProvider = AsyncNotifierProvider<ExchangeLogsListNotifier, ExchangeLogsListState>(
  ExchangeLogsListNotifier.new,
);

/// Notifier du journal des échanges, rechargé à chaque nouvelle trace.
class ExchangeLogsListNotifier extends AsyncNotifier<ExchangeLogsListState> {
  /// Cas d'usage de lecture du journal.
  late final _getExchangeLogsUsecase = ref.read(getExchangeLogsUsecaseProvider);

  @override
  Future<ExchangeLogsListState> build() async {
    final result = await _getExchangeLogsUsecase(const NoParams());
    return result.fold(
      onFailure: (GetExchangeLogsFailure failure) {
        final message = switch (failure) {
          GetExchangeLogsFailure.invalidData => ref.l10n.homeGetContentsInvalidData,
          GetExchangeLogsFailure.storageError => ref.l10n.homeGetContentsStorageError,
          GetExchangeLogsFailure.unknown => ref.l10n.homeGetContentsUnknown,
        };
        return ExchangeLogsListState(logs: const [], failureMessage: message);
      },
      onSuccess: (List<ExchangeLog> logs) => ExchangeLogsListState(logs: logs),
    );
  }
}

/// État du journal des échanges.
class ExchangeLogsListState extends NotifierState {
  /// Crée un [ExchangeLogsListState].
  ///
  /// - [logs] : traces, de la plus récente à la plus ancienne.
  /// - [failureMessage] : message d'erreur éventuel.
  ExchangeLogsListState({required this.logs, super.failureMessage});

  /// Traces, de la plus récente à la plus ancienne.
  final List<ExchangeLog> logs;
}
