import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/service.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.config.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.entity.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.repository.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.repository.drift.dart';
import 'package:bedbug/infra/resources/data.exception.dart';
import 'package:bedbug/infra/resources/datasource.exception.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.drift.dart';
import 'package:bedbug/infra/resources/signature/signature/signature.config.dart';
import 'package:bedbug/infra/resources/signature/signature/signature.entity.dart';
import 'package:bedbug/logic/services/reaction/merge_reactions/merge_reactions.failure.dart';
import 'package:bedbug/logic/services/reaction/merge_reactions/merge_reactions.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [MergeReactionsService].
final mergeReactionsServiceProvider = Provider<MergeReactionsService>((ref) {
  return MergeReactionsService(ref.read(reactionRepositoryProvider), ref.read(errorLogRepositoryProvider));
});

/// Intègre un lot de réactions aux réactions de leurs contenus, en respectant les règles qui les bornent.
///
/// Une réaction arrive par deux chemins : postée par l'utilisateur, ou reçue d'un pair. Dans les deux cas, les mêmes
/// règles s'appliquent, et c'est ce service qui les garantit :
/// - une réaction reçue ne passe par aucun formulaire : elle est normalisée, et écartée si son bedbug contient un mot
///   ou si sa bulle est invalide ;
/// - une signature n'a qu'une réaction par contenu : la nouvelle remplace l'ancienne, sauf si l'ancienne est plus
///   récente (une version périmée reçue d'un pair ne doit pas écraser la dernière) ;
/// - un contenu ne garde que ses [maxReactionsPerContent] réactions les plus récentes, pour que son poids reste borné
///   quoi qu'envoient les pairs.
///
/// Un échange apporte des centaines de réactions : les traiter une à une coûterait trois requêtes chacune, sans
/// garantie qu'une coupure ne laisse pas un contenu à moitié fusionné. Le lot est donc lu en une requête, fusionné en
/// mémoire dans l'ordre reçu (chaque réaction voit les précédentes), puis écrit en une seule transaction.
///
/// Retourne, pour chaque réaction du lot et dans le même ordre, la réaction effectivement conservée pour son auteur,
/// ou `null` si elle a été écartée.
class MergeReactionsService extends Service<MergeReactionsParams, MergeReactionsFailure, List<Reaction?>> {
  /// Crée un [MergeReactionsService].
  MergeReactionsService(this._reactionRepository, this._errorLogRepository);

  final ReactionRepository _reactionRepository;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<MergeReactionsFailure, List<Reaction?>>> call(MergeReactionsParams params) async {
    try {
      final normalized = [for (final reaction in params.reactions) _normalize(reaction)];
      final contentIds = {
        for (final reaction in normalized)
          if (reaction != null) reaction.contentId,
      };
      if (contentIds.isEmpty) {
        return Right(normalized);
      }

      final existing = await _reactionRepository.getAllByContentIds(contentIds);
      final reactionsByContent = <String, List<Reaction>>{};
      for (final reaction in existing) {
        reactionsByContent.putIfAbsent(reaction.contentId, () => []).add(reaction);
      }

      final kept = <Reaction?>[];
      for (final reaction in normalized) {
        if (reaction == null) {
          kept.add(null);
          continue;
        }
        kept.add(_mergeInto(reactionsByContent.putIfAbsent(reaction.contentId, () => []), reaction));
      }

      final existingById = {for (final reaction in existing) reaction.id: reaction};
      final mergedReactions = [for (final reactions in reactionsByContent.values) ...reactions];
      final mergedIds = {for (final reaction in mergedReactions) reaction.id};
      // Une réaction déjà en base et restée telle quelle est la même instance : seules les nouvelles sont écrites.
      final savedReactions = [
        for (final reaction in mergedReactions)
          if (!identical(existingById[reaction.id], reaction)) reaction,
      ];
      final removedIds = existingById.keys.toSet().difference(mergedIds);
      if (savedReactions.isNotEmpty || removedIds.isNotEmpty) {
        await _reactionRepository.addReplacing(savedReactions, removedIds);
      }
      return Right(kept);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('MergeReactionsService', error, stackTrace);
      return const Left(MergeReactionsFailure.storageError);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('MergeReactionsService', error, stackTrace);
      return const Left(MergeReactionsFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('MergeReactionsService', error, stackTrace);
      await _errorLogRepository.record(source: 'MergeReactionsService', error: error, stackTrace: stackTrace);
      return const Left(MergeReactionsFailure.unknown);
    }
  }

  /// Intègre [reaction] aux réactions [contentReactions] de son contenu, modifiées sur place, et retourne la réaction
  /// conservée pour son auteur.
  ///
  /// Si l'auteur a déjà une version au moins aussi récente, rien ne change et c'est elle qui est retournée. Sinon la
  /// réaction remplace ses versions précédentes, puis les plus anciennes au-delà du plafond sont écartées, elle
  /// comprise si elle est plus ancienne que toutes celles que le plafond garde.
  ///
  /// - [contentReactions] : réactions actuelles du contenu, y compris celles déjà fusionnées depuis ce lot.
  /// - [reaction] : réaction normalisée à intégrer.
  Reaction _mergeInto(List<Reaction> contentReactions, Reaction reaction) {
    for (final authorReaction in contentReactions) {
      if (authorReaction.authorId == reaction.authorId && !authorReaction.updatedAt.isBefore(reaction.updatedAt)) {
        return authorReaction;
      }
    }
    contentReactions
      ..removeWhere((other) => other.authorId == reaction.authorId)
      ..insert(0, reaction)
      ..sort((first, second) => second.updatedAt.compareTo(first.updatedAt));
    if (contentReactions.length > maxReactionsPerContent) {
      contentReactions.removeRange(maxReactionsPerContent, contentReactions.length);
    }
    return reaction;
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
