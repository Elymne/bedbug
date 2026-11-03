import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/content/reaction/reaction.entity.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.hive.dart';
import 'package:bedbug/services/reaction/merge_reaction/merge_reaction.failure.dart';
import 'package:bedbug/services/reaction/merge_reaction/merge_reaction.params.dart';
import 'package:bedbug/services/reaction/merge_reaction/merge_reaction.service.dart';
import 'package:bedbug/usecases/reaction/save_reaction/save_reaction.failure.dart';
import 'package:bedbug/usecases/reaction/save_reaction/save_reaction.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SaveReactionUsecase].
final saveReactionUsecaseProvider = Provider<SaveReactionUsecase>((ref) {
  return SaveReactionUsecase(ref.read(mergeReactionServiceProvider), ref.read(errorLogRepositoryProvider));
});

/// Enregistre une réaction de l'utilisateur sur un contenu.
///
/// Une réaction ne doit pas pouvoir contourner les règles qui bornent les réactions d'un contenu : ce use case passe
/// par [MergeReactionService], comme l'import des réactions reçues des pairs.
///
/// Retourne la réaction effectivement conservée pour cet auteur.
class SaveReactionUsecase extends Usecase<SaveReactionParams, SaveReactionFailure, Reaction> {
  /// Crée un [SaveReactionUsecase].
  SaveReactionUsecase(this._mergeReactionService, this._errorLogRepository);

  final MergeReactionService _mergeReactionService;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<SaveReactionFailure, Reaction>> call(SaveReactionParams params) async {
    try {
      final result = await _mergeReactionService(MergeReactionParams(reaction: params.reaction));
      return result.fold<Either<SaveReactionFailure, Reaction>>(
        onFailure: (MergeReactionFailure failure) => Left(switch (failure) {
          MergeReactionFailure.invalidReaction => SaveReactionFailure.invalidReaction,
          MergeReactionFailure.storageError => SaveReactionFailure.storageError,
          MergeReactionFailure.unknown => SaveReactionFailure.unknown,
        }),
        onSuccess: (Reaction kept) => Right(kept),
      );
    } catch (error, stackTrace) {
      AppLogger.error('SaveReactionUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'SaveReactionUsecase', error: error, stackTrace: stackTrace);
      return const Left(SaveReactionFailure.unknown);
    }
  }
}
