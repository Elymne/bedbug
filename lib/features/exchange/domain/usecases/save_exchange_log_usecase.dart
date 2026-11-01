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

/// Nombre maximal de traces conservées dans le journal des échanges.
///
/// Le journal sert à comprendre ce qui vient de se passer : les rencontres anciennes n'apprennent plus rien, et un
/// téléphone souvent entouré ne doit pas le voir grossir sans fin.
const int maxExchangeLogs = 300;

/// Provider du [SaveExchangeLogUsecase].
final saveExchangeLogUsecaseProvider = Provider<SaveExchangeLogUsecase>((ref) {
  return SaveExchangeLogUsecase(ref.read(exchangeLogRepositoryProvider));
});

/// Ajoute une rencontre au journal des échanges, sans dépasser [maxExchangeLogs] traces.
///
/// Les échanges se déroulent en arrière-plan, sans témoin : sans cette trace, rien ne permettrait de savoir pourquoi
/// un contenu n'est pas arrivé.
class SaveExchangeLogUsecase extends Usecase<SaveExchangeLogParams, SaveExchangeLogFailure, void> {
  /// Crée un [SaveExchangeLogUsecase].
  SaveExchangeLogUsecase(this._exchangeLogRepository);

  final ExchangeLogRepository _exchangeLogRepository;

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
      return const Left(SaveExchangeLogFailure.unknown);
    }
  }
}

/// Échecs possibles du [SaveExchangeLogUsecase].
enum SaveExchangeLogFailure {
  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de l'enregistrement.
  unknown,
}

/// Paramètres du [SaveExchangeLogUsecase].
class SaveExchangeLogParams extends Params {
  /// Crée des [SaveExchangeLogParams].
  ///
  /// - [log] : trace à enregistrer.
  const SaveExchangeLogParams({required this.log});

  /// Trace à enregistrer.
  final ExchangeLog log;
}
