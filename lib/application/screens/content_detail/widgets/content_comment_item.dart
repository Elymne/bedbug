import 'package:bedbug/application/notifiers/content_author_notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_prefixes.dart';
import 'package:bedbug/application/style/app_text_styles.dart';
import 'package:bedbug/application/widgets/signature/app_signature_avatar.dart';
import 'package:bedbug/application/widgets/texts/app_prefixed_text.dart';
import 'package:bedbug/features/content/domain/entities/comment.dart';
import 'package:bedbug/features/signature/domain/entities/anonymous_signature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Un commentaire de la liste affichée sur la page de détail d'un contenu.
///
/// Affiche la signature de l'auteur (`s/pseudo` puis son bedbug, animé avec
/// sa couleur et son intensité), puis le corps du commentaire. Le temps de
/// charger la signature, l'auteur est présenté comme anonyme, pour que la
/// ligne garde sa place au lieu d'apparaître après coup.
class ContentCommentItem extends ConsumerWidget {
  /// Crée un [ContentCommentItem].
  ///
  /// - [comment] : commentaire à afficher.
  /// - [isAnimating] : `false` pour figer le bedbug de l'auteur.
  const ContentCommentItem({super.key, required this.comment, required this.isAnimating});

  /// Commentaire à afficher.
  final Comment comment;

  /// Indique si le bedbug de l'auteur est animé.
  final bool isAnimating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAuthorNotifierWatcher = ref.watch(contentAuthorNotifierProvider(comment.authorId));
    final author = contentAuthorNotifierWatcher.value ?? anonymousSignature;
    final authorColorArgb = author.colorArgb;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Row(
          spacing: 8,
          children: [
            AppPrefixedText(prefix: AppPrefixes.signature, text: author.pseudo, style: AppTextStyles.contentMeta),
            AppSignatureAvatar(
              avatarText: author.avatarText,
              ghostColor: authorColorArgb == null ? AppColors.primary : Color(authorColorArgb),
              ghostSpeed: author.ghostSpeed,
              fontSize: 14,
              isAnimating: isAnimating,
            ),
          ],
        ),
        Text(comment.body, style: AppTextStyles.contentPreview),
      ],
    );
  }
}
