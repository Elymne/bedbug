import 'package:bedbug/application/notifiers/content_author_notifier.dart';
import 'package:bedbug/application/notifiers/delete_own_content_notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_text_styles.dart';
import 'package:bedbug/application/widgets/buttons/app_close_button.dart';
import 'package:bedbug/application/widgets/dialogs/delete_content_dialog.dart';
import 'package:bedbug/application/widgets/snackbars/app_snackbar.dart';
import 'package:bedbug/application/widgets/tags/app_tag.dart';
import 'package:bedbug/application/widgets/user/app_user_avatar.dart';
import 'package:bedbug/features/user/domain/entities/anonymous_user.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:bedbug/shared/extensions/datetime_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Squelette commun à toutes les pages de détail de contenu.
///
/// Affiche le flair, puis l'auteur et le temps écoulé depuis la création
/// séparés par un point, puis le titre, puis le corps spécifique au type
/// de contenu ([contentBody]), puis les chips (bounces).
class ContentDetailSkeleton extends ConsumerWidget {
  /// Crée un [ContentDetailSkeleton].
  ///
  /// - [title] : titre du contenu, affiché en gras.
  /// - [flair] : flair libre du contenu, sans le `/` initial.
  /// - [authorId] : identifiant de l'auteur du contenu, dont le profil est affiché.
  /// - [contentBody] : widget spécifique au type de contenu.
  /// - [createdAt] : date de création du contenu, utilisée pour le temps écoulé.
  /// - [bounce] : nombre de rebonds du contenu, affiché dans un chip.
  /// - [onClose] : callback déclenché lors du tap sur le bouton de fermeture.
  /// - [contentId] : identifiant du contenu, utilisé pour sa suppression.
  /// - [isOwned] : `true` si le contenu a été publié par l'utilisateur, qui peut alors le supprimer.
  const ContentDetailSkeleton({
    super.key,
    required this.contentId,
    required this.isOwned,
    required this.title,
    required this.flair,
    required this.authorId,
    required this.contentBody,
    required this.createdAt,
    required this.bounce,
    required this.onClose,
  });

  /// Identifiant du contenu, utilisé pour sa suppression.
  final String contentId;

  /// Indique si le contenu a été publié par l'utilisateur, qui peut alors le supprimer.
  final bool isOwned;

  /// Titre du contenu, affiché en gras.
  final String title;

  /// Flair libre du contenu, sans le `/` initial.
  final String flair;

  /// Identifiant de l'auteur du contenu, dont le profil est affiché.
  final String authorId;

  /// Widget spécifique au type de contenu.
  final Widget contentBody;

  /// Date de création du contenu, utilisée pour le temps écoulé.
  final DateTime createdAt;

  /// Nombre de rebonds du contenu, affiché dans un chip.
  final int bounce;

  /// Callback déclenché lors du tap sur le bouton de fermeture.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAuthorNotifierWatcher = ref.watch(contentAuthorNotifierProvider(authorId));
    // Le temps de charger le profil, l'auteur est présenté comme anonyme :
    // la ligne garde sa place au lieu d'apparaître après coup.
    final author = contentAuthorNotifierWatcher.value ?? anonymousUser;
    final authorColorArgb = author.colorArgb;
    final authorColor = authorColorArgb == null ? AppColors.primary : Color(authorColorArgb);
    final deleteOwnContentNotifierWatcher = ref.watch(deleteOwnContentNotifierProvider);
    // Désactivé pendant une suppression en cours, pour éviter un double tap.
    final VoidCallback? onDelete = deleteOwnContentNotifierWatcher.isLoading ? null : () => _onDelete(context, ref);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppCloseButton(onTap: onClose),
                const Spacer(),
                if (isOwned)
                  IconButton(
                    onPressed: onDelete,
                    tooltip: context.loc.deleteContentButton,
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.failure),
                  ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.signal_wifi_connected_no_internet_4),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: .start,
                          children: [
                            Text('/$flair', style: AppTextStyles.contentMeta),
                            Row(
                              spacing: 6,
                              children: [
                                AppUserAvatar(
                                  avatarText: author.avatarText,
                                  ghostColor: authorColor,
                                  ghostSpeed: author.ghostSpeed,
                                  fontSize: 14,
                                ),
                                Text('u/${author.pseudo}  •  ${createdAt.timeAgo}', style: AppTextStyles.contentMeta),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(title, style: AppTextStyles.contentTitle.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    contentBody,
                    const SizedBox(height: 20),
                    Row(
                      spacing: 8,
                      children: [AppTag(label: '$bounce bounces', color: AppColors.primary)],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Demande confirmation, supprime le contenu puis ferme la page de détail.
  ///
  /// En cas d'échec, la page reste ouverte et l'erreur est affichée.
  Future<void> _onDelete(BuildContext context, WidgetRef ref) async {
    final isConfirmed = await DeleteContentDialog.show(context);
    if (!isConfirmed || !context.mounted) {
      return;
    }

    final failureMessage = await ref.read(deleteOwnContentNotifierProvider.notifier).delete(contentId);
    if (!context.mounted) {
      return;
    }
    if (failureMessage != null) {
      AppSnackbar.showError(context, failureMessage);
      return;
    }
    AppSnackbar.showSuccess(context, context.loc.deleteContentSuccess);
    onClose();
  }
}
