import 'package:bedbug/features/exchange/domain/entities/exchange_log.dart';
import 'package:bedbug/features/exchange/domain/repositories/exchange_log_repository.dart';
import 'package:bedbug/features/exchange/infrastructure/datasources/hive_exchange_log_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetExchangeLogsUsecase].
final getExchangeLogsUsecaseProvider = Provider<GetExchangeLogsUsecase>((ref) {
  return GetExchangeLogsUsecase(ref.read(exchangeLogRepositoryProvider));
});

/// Récupère le journal des échanges, du plus récent au plus ancien.
///
/// Les échanges n'ont pas de témoin : c'est le seul moyen de diagnostiquer un transfert sans brancher le téléphone à
/// un ordinateur.
class GetExchangeLogsUsecase extends Usecase<NoParams, GetExchangeLogsFailure, List<ExchangeLog>> {
  /// Crée un [GetExchangeLogsUsecase].
  GetExchangeLogsUsecase(this._exchangeLogRepository);

  final ExchangeLogRepository _exchangeLogRepository;

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
      return const Left(GetExchangeLogsFailure.unknown);
    }
  }
}

/// Échecs possibles du [GetExchangeLogsUsecase].
enum GetExchangeLogsFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la lecture.
  unknown,
}
