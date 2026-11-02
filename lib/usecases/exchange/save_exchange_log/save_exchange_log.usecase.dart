import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log.repository.hive.dart';
import 'package:bedbug/resources/exchange/exchange_log.repository.dart';
import 'package:bedbug/resources/exchange/exchange_log.repository.hive.dart';
import 'package:bedbug/usecases/exchange/save_exchange_log/save_exchange_log.failure.dart';
import 'package:bedbug/usecases/exchange/save_exchange_log/save_exchange_log.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nombre maximal de traces conservées dans le journal des échanges.
///
/// Le journal sert à comprendre ce qui vient de se passer : les rencontres anciennes n'apprennent plus rien, et un
/// téléphone souvent entouré ne doit pas le voir grossir sans fin.
const int maxExchangeLogs = 300;

/// Provider du [SaveExchangeLogUsecase].
final saveExchangeLogUsecaseProvider = Provider<SaveExchangeLogUsecase>((ref) {
  return SaveExchangeLogUsecase(ref.read(exchangeLogRepositoryProvider), ref.read(errorLogRepositoryProvider));
});

/// Ajoute une rencontre au journal des échanges, sans dépasser [maxExchangeLogs] traces.
///
/// Les échanges se déroulent en arrière-plan, sans témoin : sans cette trace, rien ne permettrait de savoir pourquoi
/// un contenu n'est pas arrivé.
class SaveExchangeLogUsecase extends Usecase<SaveExchangeLogParams, SaveExchangeLogFailure, void> {
  /// Crée un [SaveExchangeLogUsecase].
  SaveExchangeLogUsecase(this._exchangeLogRepository, this._errorLogRepository);

  final ExchangeLogRepository _exchangeLogRepository;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<SaveExchangeLogFailure, void>> call(SaveExchangeLogParams params) async {
    try {
      await _exchangeLogRepository.addOne(params.log);
      await _exchangeLogRepository.keepNewest(maxExchangeLogs);
      return const Right(null);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('SaveExchangeLogUsecase', error, stackTrace);
      return const Left(SaveExchangeLogFailure.storageError);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('SaveExchangeLogUsecase', error, stackTrace);
      return const Left(SaveExchangeLogFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('SaveExchangeLogUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'SaveExchangeLogUsecase', error: error, stackTrace: stackTrace);
      return const Left(SaveExchangeLogFailure.unknown);
    }
  }
}
