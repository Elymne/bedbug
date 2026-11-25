import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.entity.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.drift.dart';
import 'package:bedbug/logic/services/reaction/merge_reactions/merge_reactions.failure.dart';
import 'package:bedbug/logic/services/reaction/merge_reactions/merge_reactions.params.dart';
import 'package:bedbug/logic/services/reaction/merge_reactions/merge_reactions.service.dart';
import 'package:bedbug/logic/usecases/reaction/save_reaction/save_reaction.failure.dart';
import 'package:bedbug/logic/usecases/reaction/save_reaction/save_reaction.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SaveReactionUsecase].
final saveReactionUsecaseProvider = Provider<SaveReactionUsecase>((ref) {
  return SaveReactionUsecase(ref.read(mergeReactionsServiceProvider), ref.read(errorLogRepositoryProvider));
});

/// Enregistre une réaction de l'utilisateur sur un contenu.
///
/// Une réaction ne doit pas pouvoir contourner les règles qui bornent les réactions d'un contenu : ce use case passe
/// par [MergeReactionsService], comme l'import des réactions reçues des pairs.
///
/// Retourne la réaction effectivement conservée pour cet auteur.
class SaveReactionUsecase extends Usecase<SaveReactionParams, SaveReactionFailure, Reaction> {
  /// Crée un [SaveReactionUsecase].
  SaveReactionUsecase(this._mergeReactionsService, this._errorLogRepository);

  final MergeReactionsService _mergeReactionsService;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<SaveReactionFailure, Reaction>> call(SaveReactionParams params) async {
    try {
      final result = await _mergeReactionsService(MergeReactionsParams(reactions: [params.reaction]));
      return result.fold<Either<SaveReactionFailure, Reaction>>(
        onFailure: (MergeReactionsFailure failure) => Left(switch (failure) {
          MergeReactionsFailure.storageError => SaveReactionFailure.storageError,
          MergeReactionsFailure.unknown => SaveReactionFailure.unknown,
        }),
        onSuccess: (List<Reaction?> kept) {
          final reaction = kept.single;
          if (reaction == null) {
            return const Left(SaveReactionFailure.invalidReaction);
          }
          return Right(reaction);
        },
      );
    } catch (error, stackTrace) {
      AppLogger.error('SaveReactionUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'SaveReactionUsecase', error: error, stackTrace: stackTrace);
      return const Left(SaveReactionFailure.unknown);
    }
  }
}
