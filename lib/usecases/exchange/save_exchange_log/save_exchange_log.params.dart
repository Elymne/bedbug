import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/resources/exchange/exchange_log.entity.dart';
import 'package:bedbug/usecases/exchange/save_exchange_log/save_exchange_log.usecase.dart';

/// Paramètres du [SaveExchangeLogUsecase].
class SaveExchangeLogParams extends Params {
  /// Crée des [SaveExchangeLogParams].
  ///
  /// - [log] : trace à enregistrer.
  const SaveExchangeLogParams({required this.log});

  /// Trace à enregistrer.
  final ExchangeLog log;
}
