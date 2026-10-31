import 'package:bedbug/features/content/domain/entities/reaction.dart';
import 'package:bedbug/features/content/domain/repositories/reaction_repository.dart';
import 'package:bedbug/features/content/domain/services/reaction_merge_service.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_reaction_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SaveReactionUsecase].
final saveReactionUsecaseProvider = Provider<SaveReactionUsecase>((ref) {
  return SaveReactionUsecase(ref.read(reactionRepositoryProvider), ref.read(reactionMergeServiceProvider));
});

/// Enregistre une réaction de l'utilisateur sur un contenu.
///
/// Une réaction ne doit pas pouvoir contourner les règles qui bornent les réactions d'un contenu : ce use case les
/// applique avec [ReactionMergeService], comme l'import des réactions reçues des pairs.
///
/// Retourne la réaction effectivement conservée pour cet auteur.
class SaveReactionUsecase extends Usecase<SaveReactionParams, SaveReactionFailure, Reaction> {
  /// Crée un [SaveReactionUsecase].
  SaveReactionUsecase(this._reactionRepository, this._reactionMergeService);

  final ReactionRepository _reactionRepository;
  final ReactionMergeService _reactionMergeService;

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
      return const Left(SaveReactionFailure.unknown);
    }
  }
}

/// Échecs possibles du [SaveReactionUsecase].
enum SaveReactionFailure {
  /// Le bedbug contient un mot, ou la bulle est vide, trop longue ou sur plusieurs lignes.
  invalidReaction,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de l'enregistrement.
  unknown,
}

/// Paramètres du [SaveReactionUsecase].
class SaveReactionParams extends Params {
  /// Crée des [SaveReactionParams].
  ///
  /// - [reaction] : réaction à enregistrer, avant normalisation.
  const SaveReactionParams({required this.reaction});

  /// Réaction à enregistrer, avant normalisation.
  final Reaction reaction;
}
