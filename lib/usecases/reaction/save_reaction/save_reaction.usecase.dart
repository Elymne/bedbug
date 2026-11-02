import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/content/reaction.entity.dart';
import 'package:bedbug/resources/content/reaction.repository.dart';
import 'package:bedbug/resources/content/reaction.repository.hive.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log.repository.hive.dart';
import 'package:bedbug/services/reaction/reaction_merge.service.dart';
import 'package:bedbug/usecases/reaction/save_reaction/save_reaction.failure.dart';
import 'package:bedbug/usecases/reaction/save_reaction/save_reaction.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SaveReactionUsecase].
final saveReactionUsecaseProvider = Provider<SaveReactionUsecase>((ref) {
  return SaveReactionUsecase(
    ref.read(reactionRepositoryProvider),
    ref.read(reactionMergeServiceProvider),
    ref.read(errorLogRepositoryProvider),
  );
});

/// Enregistre une réaction de l'utilisateur sur un contenu.
///
/// Une réaction ne doit pas pouvoir contourner les règles qui bornent les réactions d'un contenu : ce use case les
/// applique avec [ReactionMergeService], comme l'import des réactions reçues des pairs.
///
/// Retourne la réaction effectivement conservée pour cet auteur.
class SaveReactionUsecase extends Usecase<SaveReactionParams, SaveReactionFailure, Reaction> {
  /// Crée un [SaveReactionUsecase].
  SaveReactionUsecase(this._reactionRepository, this._reactionMergeService, this._errorLogRepository);

  final ReactionRepository _reactionRepository;
  final ReactionMergeService _reactionMergeService;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<SaveReactionFailure, Reaction>> call(SaveReactionParams params) async {
    try {
      final reaction = _reactionMergeService.normalize(params.reaction);
      if (reaction == null) {
        return const Left(SaveReactionFailure.invalidReaction);
      }

      final existingReactions = await _reactionRepository.getAllByContentId(reaction.contentId);
      final merge = _reactionMergeService.merge(existingReactions, reaction);
      if (!merge.isNewReactionKept) {
        return Right(merge.kept);
      }

      await _reactionRepository.deleteMany(merge.replacedIds);
      await _reactionRepository.addOne(reaction);
      if (merge.overflowIds.isNotEmpty) {
        await _reactionRepository.deleteMany(merge.overflowIds);
      }

      return Right(reaction);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('SaveReactionUsecase', error, stackTrace);
      return const Left(SaveReactionFailure.storageError);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('SaveReactionUsecase', error, stackTrace);
      return const Left(SaveReactionFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('SaveReactionUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'SaveReactionUsecase', error: error, stackTrace: stackTrace);
      return const Left(SaveReactionFailure.unknown);
    }
  }
}
