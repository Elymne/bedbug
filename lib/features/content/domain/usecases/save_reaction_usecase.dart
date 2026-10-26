import 'package:bedbug/features/content/domain/entities/reaction.dart';
import 'package:bedbug/features/content/domain/extensions/reaction_text_extension.dart';
import 'package:bedbug/features/content/domain/repositories/reaction_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_reaction_repository.dart';
import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:bedbug/features/signature/domain/extensions/signature_text_extension.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SaveReactionUsecase].
final saveReactionUsecaseProvider = Provider<SaveReactionUsecase>((ref) {
  return SaveReactionUsecase(ref.read(reactionRepositoryProvider));
});

/// Enregistre une réaction sur un contenu, en appliquant les règles qui bornent leur nombre.
///
/// Les réactions circulent de pair à pair sans identité vérifiable : ce use
/// case est le seul point d'entrée, qu'elles viennent de l'utilisateur ou,
/// plus tard, d'un pair. Il garantit ainsi partout que :
/// - le bedbug ne contient pas de mot et la bulle respecte sa longueur
///   maximale (une réaction reçue ne passe par aucun formulaire) ;
/// - l'intensité du ghost reste dans ses bornes, pour qu'une valeur
///   extrême reçue d'un pair ne fige ni ne fasse planter l'animation ;
/// - une signature n'a qu'une réaction par contenu : la nouvelle remplace
///   l'ancienne, sauf si l'ancienne est plus récente (une version périmée
///   reçue d'un pair ne doit pas écraser la dernière) ;
/// - un contenu ne garde que ses [maxReactionsPerContent] réactions les plus
///   récentes, pour que son poids reste borné quoi qu'envoient les pairs.
///
/// Retourne la réaction effectivement conservée pour cet auteur.
class SaveReactionUsecase extends Usecase<SaveReactionParams, SaveReactionFailure, Reaction> {
  /// Crée un [SaveReactionUsecase].
  SaveReactionUsecase(this._reactionRepository);

  final ReactionRepository _reactionRepository;

  @override
  Future<Either<SaveReactionFailure, Reaction>> call(SaveReactionParams params) async {
    try {
      final avatarText = params.reaction.avatarText.trim();
      final bubbleText = params.reaction.bubbleText?.trim() ?? '';
      if (!avatarText.isValidAvatarText || !bubbleText.isValidReactionBubble) {
        return const Left(SaveReactionFailure.invalidReaction);
      }

      final reaction = Reaction(
        id: params.reaction.id,
        createdAt: params.reaction.createdAt,
        updatedAt: params.reaction.updatedAt,
        contentId: params.reaction.contentId,
        authorId: params.reaction.authorId,
        avatarText: avatarText,
        bubbleText: bubbleText.isEmpty ? null : bubbleText,
        colorArgb: params.reaction.colorArgb,
        ghostSpeed: params.reaction.ghostSpeed.clamp(minGhostSpeed, maxGhostSpeed),
      );

      final existingReactions = await _reactionRepository.getAllByContentId(reaction.contentId);
      final authorReactions = existingReactions.where((existing) => existing.authorId == reaction.authorId).toList();
      for (final authorReaction in authorReactions) {
        if (!authorReaction.updatedAt.isBefore(reaction.updatedAt)) {
          return Right(authorReaction);
        }
      }

      await _reactionRepository.deleteMany(authorReactions.map((authorReaction) => authorReaction.id).toList());
      await _reactionRepository.addOne(reaction);

      final keptReactions = [reaction, ...existingReactions.where((existing) => existing.authorId != reaction.authorId)]
        ..sort((first, second) => second.updatedAt.compareTo(first.updatedAt));
      if (keptReactions.length > maxReactionsPerContent) {
        final overflowIds = keptReactions.skip(maxReactionsPerContent).map((overflow) => overflow.id).toList();
        await _reactionRepository.deleteMany(overflowIds);
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
  /// Le bedbug contient un mot, ou la bulle est trop longue ou sur plusieurs lignes.
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
