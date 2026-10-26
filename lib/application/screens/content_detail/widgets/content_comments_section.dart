import 'package:bedbug/application/notifiers/content_comments_notifier.dart';
import 'package:bedbug/application/screens/content_detail/widgets/comment_composer_sheet.dart';
import 'package:bedbug/application/screens/content_detail/widgets/content_comment_item.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_text_styles.dart';
import 'package:bedbug/application/widgets/texts/app_loading_text.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nombre de commentaires dont le bedbug de l'auteur est animé, les premiers de la liste.
///
/// Chaque bedbug animé fait tourner quatre animations : au-delà, avec
/// jusqu'à 100 commentaires par contenu, la page saccaderait. Les suivants
/// restent affichés dans la couleur de leur auteur, mais figés.
const int _kAnimatedCommentCount = 12;

/// Section des commentaires de la page de détail d'un contenu.
///
/// Affiche les commentaires dans un ordre aléatoire, séparés par un trait
/// gris, et un bouton pour commenter.
class ContentCommentsSection extends ConsumerWidget {
  /// Crée une [ContentCommentsSection].
  ///
  /// - [contentId] : identifiant du contenu dont on affiche les commentaires.
  const ContentCommentsSection({super.key, required this.contentId});

  /// Identifiant du contenu dont on affiche les commentaires.
  final String contentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;
    final contentCommentsNotifierWatcher = ref.watch(contentCommentsNotifierProvider(contentId));
    final commentCount = contentCommentsNotifierWatcher.value?.comments.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Row(
          children: [
            Text(l10n.contentCommentsTitle(commentCount), style: AppTextStyles.contentTitle),
            const Spacer(),
            TextButton.icon(
              onPressed: () => CommentComposerSheet.show(context, contentId: contentId),
              icon: const Icon(Icons.mode_comment_outlined),
              label: Text(l10n.contentCommentButton),
            ),
          ],
        ),
        contentCommentsNotifierWatcher.when(
          loading: () => const AppLoadingText(),
          error: (_, _) => Text(l10n.contentCommentsLoadError),
          data: (state) {
            if (state.failureMessage != null) {
              return Text(state.failureMessage!);
            }
            if (state.comments.isEmpty) {
              return Text(l10n.contentCommentsEmpty, style: const TextStyle(color: AppColors.disabled));
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, comment) in state.comments.indexed) ...[
                  if (index > 0) const Divider(height: 24, thickness: 1, color: AppColors.border),
                  ContentCommentItem(comment: comment, isAnimating: index < _kAnimatedCommentCount),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
