import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.repository.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.repository.drift.dart';
import 'package:bedbug/infra/resources/datasource.exception.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.drift.dart';
import 'package:bedbug/logic/usecases/reaction/count_content_reactions/count_content_reactions.failure.dart';
import 'package:bedbug/logic/usecases/reaction/count_content_reactions/count_content_reactions.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [CountContentReactionsUsecase].
final countContentReactionsUsecaseProvider = Provider<CountContentReactionsUsecase>((ref) {
  return CountContentReactionsUsecase(ref.read(reactionRepositoryProvider), ref.read(errorLogRepositoryProvider));
});

/// Compte les réactions d'un contenu, sans les charger.
///
/// Le nombre de réactions est affiché à côté des bounces, jusque dans les tuiles du fil, qui le lisent avec leur
/// contenu. Quand l'utilisateur réagit, seul ce nombre change : le relire suffit à mettre à jour la tuile restée dans
/// la liste, sans charger toutes les réactions ni relire la liste entière.
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
