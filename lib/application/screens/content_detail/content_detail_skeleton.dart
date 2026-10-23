import 'package:bedbug/application/screens/content_detail/content_author_notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_text_styles.dart';
import 'package:bedbug/application/widgets/buttons/app_close_button.dart';
import 'package:bedbug/application/widgets/tags/app_tag.dart';
import 'package:bedbug/application/widgets/user/app_user_avatar.dart';
import 'package:bedbug/features/user/domain/entities/anonymous_user.dart';
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
  const ContentDetailSkeleton({
    super.key,
    required this.title,
    required this.flair,
    required this.authorId,
    required this.contentBody,
    required this.createdAt,
    required this.bounce,
    required this.onClose,
  });

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

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: AppCloseButton(onTap: onClose),
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
}
