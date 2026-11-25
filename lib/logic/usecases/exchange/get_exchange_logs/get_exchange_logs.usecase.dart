import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/infra/resources/data.exception.dart';
import 'package:bedbug/infra/resources/datasource.exception.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.drift.dart';
import 'package:bedbug/infra/resources/exchange/exchange_log/exchange_log.entity.dart';
import 'package:bedbug/infra/resources/exchange/exchange_log/exchange_log.repository.dart';
import 'package:bedbug/infra/resources/exchange/exchange_log/exchange_log.repository.drift.dart';
import 'package:bedbug/logic/usecases/exchange/get_exchange_logs/get_exchange_logs.failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetExchangeLogsUsecase].
final getExchangeLogsUsecaseProvider = Provider<GetExchangeLogsUsecase>((ref) {
  return GetExchangeLogsUsecase(ref.read(exchangeLogRepositoryProvider), ref.read(errorLogRepositoryProvider));
});

/// Récupère le journal des échanges, du plus récent au plus ancien.
///
/// Les échanges n'ont pas de témoin : c'est le seul moyen de diagnostiquer un transfert sans brancher le téléphone à
/// un ordinateur.
class GetExchangeLogsUsecase extends Usecase<NoParams, GetExchangeLogsFailure, List<ExchangeLog>> {
  /// Crée un [GetExchangeLogsUsecase].
  GetExchangeLogsUsecase(this._exchangeLogRepository, this._errorLogRepository);

  final ExchangeLogRepository _exchangeLogRepository;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<GetExchangeLogsFailure, List<ExchangeLog>>> call(NoParams params) async {
    try {
      return Right(await _exchangeLogRepository.getAllNewestFirst());
    } on DataException catch (error, stackTrace) {
      AppLogger.error('GetExchangeLogsUsecase', error, stackTrace);
      return const Left(GetExchangeLogsFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('GetExchangeLogsUsecase', error, stackTrace);
      return const Left(GetExchangeLogsFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('GetExchangeLogsUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'GetExchangeLogsUsecase', error: error, stackTrace: stackTrace);
      return const Left(GetExchangeLogsFailure.unknown);
    }
  }
}
