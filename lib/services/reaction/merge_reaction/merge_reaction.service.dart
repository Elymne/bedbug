import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/service.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/content/reaction/reaction.config.dart';
import 'package:bedbug/resources/content/reaction/reaction.entity.dart';
import 'package:bedbug/resources/content/reaction/reaction.repository.dart';
import 'package:bedbug/resources/content/reaction/reaction.repository.hive.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.hive.dart';
import 'package:bedbug/resources/signature/signature/signature.config.dart';
import 'package:bedbug/resources/signature/signature/signature.entity.dart';
import 'package:bedbug/services/reaction/merge_reaction/merge_reaction.failure.dart';
import 'package:bedbug/services/reaction/merge_reaction/merge_reaction.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [MergeReactionService].
final mergeReactionServiceProvider = Provider<MergeReactionService>((ref) {
  return MergeReactionService(ref.read(reactionRepositoryProvider), ref.read(errorLogRepositoryProvider));
});

/// Intègre une réaction aux réactions de son contenu, en respectant les règles qui les bornent.
///
/// Une réaction arrive par deux chemins : postée par l'utilisateur, ou reçue d'un pair. Dans les deux cas, les mêmes
/// règles s'appliquent, et c'est ce service qui les garantit :
/// - une réaction reçue ne passe par aucun formulaire : elle est normalisée, et refusée si son bedbug contient un mot
///   ou si sa bulle est invalide ;
/// - une signature n'a qu'une réaction par contenu : la nouvelle remplace l'ancienne, sauf si l'ancienne est plus
///   récente (une version périmée reçue d'un pair ne doit pas écraser la dernière) ;
/// - un contenu ne garde que ses [maxReactionsPerContent] réactions les plus récentes, pour que son poids reste borné
///   quoi qu'envoient les pairs.
///
/// Retourne la réaction effectivement conservée pour cet auteur.
class MergeReactionService extends Service<MergeReactionParams, MergeReactionFailure, Reaction> {
  /// Crée un [MergeReactionService].
  MergeReactionService(this._reactionRepository, this._errorLogRepository);

  final ReactionRepository _reactionRepository;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<MergeReactionFailure, Reaction>> call(MergeReactionParams params) async {
    try {
      final reaction = _normalize(params.reaction);
      if (reaction == null) {
        return const Left(MergeReactionFailure.invalidReaction);
      }

      final existing = await _reactionRepository.getAllByContentId(reaction.contentId);
      final authorReactions = existing.where((other) => other.authorId == reaction.authorId).toList();
      for (final authorReaction in authorReactions) {
        if (!authorReaction.updatedAt.isBefore(reaction.updatedAt)) {
          return Right(authorReaction);
        }
      }

      final keptReactions = [reaction, ...existing.where((other) => other.authorId != reaction.authorId)]
        ..sort((first, second) => second.updatedAt.compareTo(first.updatedAt));
      final overflowIds = keptReactions.skip(maxReactionsPerContent).map((overflow) => overflow.id).toList();

      await _reactionRepository.deleteMany(authorReactions.map((authorReaction) => authorReaction.id).toList());
      await _reactionRepository.addOne(reaction);
      if (overflowIds.isNotEmpty) {
        await _reactionRepository.deleteMany(overflowIds);
      }
      return Right(reaction);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('MergeReactionService', error, stackTrace);
      return const Left(MergeReactionFailure.storageError);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('MergeReactionService', error, stackTrace);
      return const Left(MergeReactionFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('MergeReactionService', error, stackTrace);
      await _errorLogRepository.record(source: 'MergeReactionService', error: error, stackTrace: stackTrace);
      return const Left(MergeReactionFailure.unknown);
    }
  }

  /// Retourne [reaction] normalisée, ou `null` si elle est invalide.
  ///
  /// Le bedbug ne doit pas contenir de mot, et la bulle ne doit pas être vide et doit respecter sa longueur maximale.
  /// L'intensité du ghost est ramenée dans ses bornes, pour qu'une valeur extrême reçue d'un pair ne fige ni ne fasse
  /// planter l'animation.
  ///
  /// - [reaction] : réaction à enregistrer.
  Reaction? _normalize(Reaction reaction) {
    final avatarFrames = [for (final frame in reaction.avatarFrames) frame.trim()];
    final bubbleText = reaction.bubbleText.trim();
    if (!Signature.isValidAvatarFrames(avatarFrames) || !Reaction.isValidBubble(bubbleText)) {
      return null;
    }
    return Reaction(
      id: reaction.id,
      createdAt: reaction.createdAt,
      updatedAt: reaction.updatedAt,
      contentId: reaction.contentId,
      authorId: reaction.authorId,
      avatarFrames: avatarFrames,
      bubbleText: bubbleText,
      colorArgb: reaction.colorArgb,
      ghostSpeed: reaction.ghostSpeed.clamp(minGhostSpeed, maxGhostSpeed),
      avatarFrameSpeed: reaction.avatarFrameSpeed.clamp(minAvatarFrameSpeed, maxAvatarFrameSpeed),
      bubbleFont: reaction.bubbleFont,
    );
  }
}
