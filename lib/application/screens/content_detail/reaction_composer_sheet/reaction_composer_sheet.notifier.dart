import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/application/notifiers/reaction_count_changes.notifier.dart';
import 'package:bedbug/application/screens/content_detail/content_reactions_section/content_reactions_section.notifier.dart';
import 'package:bedbug/core/extensions/string_uuid_x.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.entity.dart';
import 'package:bedbug/infra/resources/signature/signature/signature.config.dart';
import 'package:bedbug/infra/resources/signature/signature/text_font.enum.dart';
import 'package:bedbug/logic/usecases/reaction/count_content_reactions/count_content_reactions.params.dart';
import 'package:bedbug/logic/usecases/reaction/count_content_reactions/count_content_reactions.usecase.dart';
import 'package:bedbug/logic/usecases/reaction/save_reaction/save_reaction.failure.dart';
import 'package:bedbug/logic/usecases/reaction/save_reaction/save_reaction.params.dart';
import 'package:bedbug/logic/usecases/reaction/save_reaction/save_reaction.usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [ReactionComposerSheetNotifier].
final reactionComposerSheetNotifierProvider = AsyncNotifierProvider.autoDispose<ReactionComposerSheetNotifier, void>(
  ReactionComposerSheetNotifier.new,
);

/// Notifier gérant l'enregistrement de la réaction de l'utilisateur sur un contenu.
///
/// Séparé de [ContentReactionsSectionNotifier] : l'enregistrement ne doit pas faire
/// repasser la liste des réactions en chargement. Son état ne porte que le
/// chargement en cours (pour désactiver le bouton) ; le résultat est retourné
/// directement à l'appelant, seul à savoir quoi afficher.
class ReactionComposerSheetNotifier extends AsyncNotifier<void> {
  /// Cas d'usage d'enregistrement d'une réaction.
  late final _saveReactionUsecase = ref.read(saveReactionUsecaseProvider);

  /// Cas d'usage de comptage des réactions d'un contenu, pour diffuser leur nouveau nombre après l'enregistrement.
  late final _countContentReactionsUsecase = ref.read(countContentReactionsUsecaseProvider);

  @override
  Future<void> build() async {}

  /// Enregistre la réaction de l'utilisateur sur [contentId] et retourne `null` en cas de succès, ou le message d'erreur à afficher.
  ///
  /// La réaction est signée par l'utilisateur du téléphone, jamais en
  /// anonyme : toutes les réactions anonymes partageraient le même auteur et
  /// se remplaceraient entre elles. Elle remplace la précédente réaction de
  /// l'utilisateur, dont la date de création est conservée. En cas de succès,
  /// les réactions du contenu sont rechargées (leur nombre affiché sur la page en découle), et leur nouveau nombre
  /// est diffusé aux listes de contenus.
  ///
  /// - [contentId] : identifiant du contenu auquel réagir.
  /// - [avatarFrames] : frames du bedbug choisi.
  /// - [bubbleText] : bulle de texte.
  /// - [colorArgb] : couleur de l'effet ghost du bedbug en ARGB 32 bits.
  /// - [ghostSpeed] : intensité de l'effet ghost du bedbug.
  /// - [avatarFrameSpeed] : vitesse de l'animation du bedbug.
  /// - [bubbleFont] : police de la bulle de texte.
  /// - [previousReaction] : réaction actuelle de l'utilisateur sur ce contenu, `null` s'il n'a pas encore réagi.
  Future<String?> save({
    required String contentId,
    required List<String> avatarFrames,
    required int colorArgb,
    required double ghostSpeed,
    required double avatarFrameSpeed,
    required String bubbleText,
    required TextFont bubbleFont,
    Reaction? previousReaction,
  }) async {
    state = const AsyncLoading();
    final now = DateTime.now();
    final result = await _saveReactionUsecase(
      SaveReactionParams(
        reaction: Reaction(
          // Même identifiant que la réaction remplacée : chez les pairs, qui ne reçoivent pas l'auteur, c'est
          // l'identifiant qui permet à la nouvelle version de remplacer l'ancienne.
          id: previousReaction?.id ?? UuidX.generate(),
          createdAt: previousReaction?.createdAt ?? now,
          updatedAt: now,
          contentId: contentId,
          authorId: localSignatureId,
          avatarFrames: avatarFrames,
          bubbleText: bubbleText,
          colorArgb: colorArgb,
          ghostSpeed: ghostSpeed,
          avatarFrameSpeed: avatarFrameSpeed,
          bubbleFont: bubbleFont,
        ),
      ),
    );
    state = const AsyncData(null);

    final failure = result.left;
    if (failure != null) {
      return switch (failure) {
        SaveReactionFailure.invalidReaction => ref.l10n.reactionInvalidError,
        SaveReactionFailure.storageError => ref.l10n.homeGetContentsStorageError,
        SaveReactionFailure.unknown => ref.l10n.reactionSaveError,
      };
    }
    ref.invalidate(contentReactionsSectionNotifierProvider(contentId));
    await _publishReactionCount(contentId);
    return null;
  }

  /// Diffuse le nouveau nombre de réactions de [contentId] aux listes de contenus restées sous la page de détail.
  ///
  /// La réaction peut en ajouter une ou remplacer celle de l'utilisateur, et le plafond de réactions d'un contenu
  /// peut en avoir écarté une autre : le nombre est donc relu plutôt que deviné. Un comptage illisible est sans
  /// gravité : la liste garde son ancien nombre jusqu'à son prochain rechargement.
  ///
  /// - [contentId] : identifiant du contenu auquel l'utilisateur vient de réagir.
  Future<void> _publishReactionCount(String contentId) async {
    final result = await _countContentReactionsUsecase(CountContentReactionsParams(contentId: contentId));
    final reactionCount = result.right;
    if (reactionCount == null || !ref.mounted) {
      return;
    }
    ref.read(reactionCountChangesNotifierProvider.notifier).publish(contentId: contentId, reactionCount: reactionCount);
  }
}
