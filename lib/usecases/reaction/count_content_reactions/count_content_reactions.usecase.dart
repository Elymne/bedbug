import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/content/reaction.repository.dart';
import 'package:bedbug/resources/content/reaction.repository.hive.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log.repository.hive.dart';
import 'package:bedbug/usecases/reaction/count_content_reactions/count_content_reactions.failure.dart';
import 'package:bedbug/usecases/reaction/count_content_reactions/count_content_reactions.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [CountContentReactionsUsecase].
final countContentReactionsUsecaseProvider = Provider<CountContentReactionsUsecase>((ref) {
  return CountContentReactionsUsecase(ref.read(reactionRepositoryProvider), ref.read(errorLogRepositoryProvider));
});

/// Compte les réactions d'un contenu, sans les charger.
///
/// Le nombre de réactions est affiché en tag à côté des bounces, jusque
/// dans les tuiles du fil : y charger toutes les réactions de chaque contenu
/// visible, juste pour les compter, serait du gaspillage.
class CountContentReactionsUsecase extends Usecase<CountContentReactionsParams, CountContentReactionsFailure, int> {
  /// Crée un [CountContentReactionsUsecase].
  CountContentReactionsUsecase(this._reactionRepository, this._errorLogRepository);

  final ReactionRepository _reactionRepository;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<CountContentReactionsFailure, int>> call(CountContentReactionsParams params) async {
    try {
      return Right(await _reactionRepository.countByContentId(params.contentId));
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('CountContentReactionsUsecase', error, stackTrace);
      return const Left(CountContentReactionsFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('CountContentReactionsUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'CountContentReactionsUsecase', error: error, stackTrace: stackTrace);
      return const Left(CountContentReactionsFailure.unknown);
    }
  }
}
