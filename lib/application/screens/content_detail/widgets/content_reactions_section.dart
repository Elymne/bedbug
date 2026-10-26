import 'package:bedbug/application/notifiers/content_author_notifier.dart';
import 'package:bedbug/application/notifiers/content_reactions_notifier.dart';
import 'package:bedbug/application/screens/content_detail/widgets/reaction_composer_sheet.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_text_styles.dart';
import 'package:bedbug/application/widgets/reactions/app_reaction_bubble.dart';
import 'package:bedbug/application/widgets/scatter/app_scatter.dart';
import 'package:bedbug/application/widgets/texts/app_loading_text.dart';
import 'package:bedbug/features/signature/domain/entities/anonymous_signature.dart';
import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:bedbug/features/signature/domain/repositories/signature_repository.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Espace minimal entre deux réactions dispersées.
///
/// Doit rester supérieur au tremblement de l'effet ghost (quelques pixels),
/// pour que deux réactions voisines ne se touchent jamais en bougeant.
const double _kReactionSpacing = 12;

/// Section des réactions de la page de détail d'un contenu.
///
/// Affiche les réactions (bedbug et bulle) dispersées au hasard sur toute la
/// largeur, sans chevauchement, et un bouton pour réagir. Toutes sont animées :
/// celles qui sortent de l'écran se mettent en pause d'elles-mêmes (voir
/// `AppGhostAnimation`). Une signature n'ayant qu'une réaction par contenu,
/// le bouton propose de modifier la réaction de l'utilisateur s'il en a déjà
/// laissé une.
class ContentReactionsSection extends ConsumerWidget {
  /// Crée une [ContentReactionsSection].
  ///
  /// - [contentId] : identifiant du contenu dont on affiche les réactions.
  const ContentReactionsSection({super.key, required this.contentId});

  /// Identifiant du contenu dont on affiche les réactions.
  final String contentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;
    final contentReactionsNotifierWatcher = ref.watch(contentReactionsNotifierProvider(contentId));
    final contentAuthorNotifierWatcher = ref.watch(contentAuthorNotifierProvider(localSignatureId));
    final reactionsState = contentReactionsNotifierWatcher.value;
    final reactionCount = reactionsState?.reactions.length ?? 0;
    final hasReacted = reactionsState?.ownReaction != null;
    final localSignature = contentAuthorNotifierWatcher.value ?? anonymousSignature;
    // Indisponible tant que les réactions ne sont pas chargées : on ne saurait
    // pas encore s'il faut créer ou modifier la réaction de l'utilisateur.
    final VoidCallback? onReact = reactionsState == null ? null : () => _react(context, reactionsState, localSignature);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Row(
          children: [
            Text(l10n.contentReactionsTitle(reactionCount), style: AppTextStyles.contentTitle),
            const Spacer(),
            TextButton.icon(
              onPressed: onReact,
              icon: const Icon(Icons.add_reaction_outlined),
              label: Text(hasReacted ? l10n.contentEditReactionButton : l10n.contentReactButton),
            ),
          ],
        ),
        contentReactionsNotifierWatcher.when(
          loading: () => const AppLoadingText(),
          error: (_, _) => Text(l10n.contentReactionsLoadError),
          data: (state) {
            if (state.failureMessage != null) {
              return Text(state.failureMessage!);
            }
            if (state.reactions.isEmpty) {
              return Text(l10n.contentReactionsEmpty, style: const TextStyle(color: AppColors.disabled));
            }
            return AppScatter(
              // Graine propre au contenu : les réactions gardent leur place tant
              // que la page reste ouverte, au lieu de sauter à chaque reconstruction.
              seed: contentId.hashCode,
              spacing: _kReactionSpacing,
              children: [
                for (final (index, reaction) in state.reactions.indexed)
                  AppReactionBubble(
                    avatarText: reaction.avatarText,
                    bubbleText: reaction.bubbleText,
                    ghostColor: reaction.colorArgb == null ? AppColors.primary : Color(reaction.colorArgb!),
                    ghostSpeed: reaction.ghostSpeed,
                    // Une bulle sur deux pincée à droite, pour varier les formes.
                    isMirrored: index.isOdd,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Ouvre la feuille de saisie de la réaction de l'utilisateur, préremplie avec sa réaction actuelle.
  ///
  /// - [context] : contexte depuis lequel ouvrir la feuille.
  /// - [reactionsState] : réactions chargées du contenu, d'où est tirée la réaction actuelle de l'utilisateur.
  /// - [localSignature] : signature de l'utilisateur du téléphone.
  void _react(BuildContext context, ContentReactionsState reactionsState, Signature localSignature) {
    ReactionComposerSheet.show(
      context,
      contentId: contentId,
      localSignature: localSignature,
      ownReaction: reactionsState.ownReaction,
    );
  }
}
