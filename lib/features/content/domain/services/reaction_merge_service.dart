import 'package:bedbug/features/content/domain/entities/reaction.dart';
import 'package:bedbug/features/content/domain/extensions/reaction_text_extension.dart';
import 'package:bedbug/features/content/domain/object_values/reaction_merge.dart';
import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:bedbug/features/signature/domain/extensions/signature_text_extension.dart';
import 'package:bedbug/shared/domain/service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [ReactionMergeService].
final reactionMergeServiceProvider = Provider<ReactionMergeService>((ref) => const ReactionMergeService());

/// Applique les règles qui bornent les réactions d'un contenu.
///
/// Les réactions circulent de pair à pair sans identité vérifiable : ces règles doivent être les mêmes, qu'une
/// réaction vienne de l'utilisateur ou d'un pair.
class ReactionMergeService extends Service {
  /// Crée un [ReactionMergeService].
  const ReactionMergeService();

  /// Retourne [reaction] normalisée, ou `null` si elle est invalide.
  ///
  /// Le bedbug ne doit pas contenir de mot, et la bulle ne doit pas être vide et doit respecter sa longueur maximale :
  /// une réaction reçue ne passe par aucun formulaire. L'intensité du ghost est ramenée dans ses bornes, pour qu'une
  /// valeur extrême reçue d'un pair ne fige ni ne fasse planter l'animation.
  ///
  /// - [reaction] : réaction à enregistrer.
  Reaction? normalize(Reaction reaction) {
    final avatarText = reaction.avatarText.trim();
    final bubbleText = reaction.bubbleText.trim();
    if (!avatarText.isValidAvatarText || !bubbleText.isValidReactionBubble) {
      return null;
    }
    return Reaction(
      id: reaction.id,
      createdAt: reaction.createdAt,
      updatedAt: reaction.updatedAt,
      contentId: reaction.contentId,
      authorId: reaction.authorId,
      avatarText: avatarText,
      bubbleText: bubbleText,
      colorArgb: reaction.colorArgb,
      ghostSpeed: reaction.ghostSpeed.clamp(minGhostSpeed, maxGhostSpeed),
      bubbleFont: reaction.bubbleFont,
    );
  }

  /// Retourne ce qu'il faut faire des réactions [existing] pour y intégrer [reaction].
  ///
  /// Une signature n'a qu'une réaction par contenu : la nouvelle remplace l'ancienne, sauf si l'ancienne est plus
  /// récente (une version périmée reçue d'un pair ne doit pas écraser la dernière). Un contenu ne garde que ses
  /// [maxReactionsPerContent] réactions les plus récentes, pour que son poids reste borné quoi qu'envoient les pairs.
  ///
  /// - [existing] : réactions déjà connues du contenu.
  /// - [reaction] : nouvelle réaction, déjà normalisée.
  ReactionMerge merge(List<Reaction> existing, Reaction reaction) {
    final authorReactions = existing.where((other) => other.authorId == reaction.authorId).toList();
    for (final authorReaction in authorReactions) {
      if (!authorReaction.updatedAt.isBefore(reaction.updatedAt)) {
        return ReactionMerge(
          kept: authorReaction,
          isNewReactionKept: false,
          replacedIds: const [],
          overflowIds: const [],
        );
      }
    }

    final keptReactions = [reaction, ...existing.where((other) => other.authorId != reaction.authorId)]
      ..sort((first, second) => second.updatedAt.compareTo(first.updatedAt));
    return ReactionMerge(
      kept: reaction,
      isNewReactionKept: true,
      replacedIds: authorReactions.map((authorReaction) => authorReaction.id).toList(),
      overflowIds: keptReactions.skip(maxReactionsPerContent).map((overflow) => overflow.id).toList(),
    );
  }
}
