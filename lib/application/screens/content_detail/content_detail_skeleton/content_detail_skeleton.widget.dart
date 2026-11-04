import 'package:bedbug/application/screens/content_detail/content_detail_author/content_detail_author.widget.dart';
import 'package:bedbug/application/screens/content_detail/content_reactions_section/content_reactions_section.widget.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/style/app_text_styles.dart';
import 'package:bedbug/application/style/tag_color_x.dart';
import 'package:bedbug/application/widgets/buttons/app_close_button.widget.dart';
import 'package:bedbug/application/widgets/buttons/delete_content_button.widget.dart';
import 'package:bedbug/application/widgets/icons/app_icon.widget.dart';
import 'package:bedbug/application/widgets/stats/content_stats.widget.dart';
import 'package:bedbug/application/widgets/tags/app_tag.widget.dart';
import 'package:bedbug/application/widgets/texts/app_prefixed_text.widget.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:bedbug/core/extensions/datetime_x.dart';
import 'package:bedbug/resources/content/content/content.config.dart';
import 'package:bedbug/resources/content/content/tag.enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Squelette commun à toutes les pages de détail de contenu.
///
/// Affiche le flair (`f/flair`), puis la signature de l'auteur (`s/pseudo`
/// suivi de son bedbug), préfixes en couleur primaire, puis le titre avec,
/// juste en dessous et en gris, le temps écoulé depuis la création écrit en
/// toutes lettres, puis les statistiques (rebonds, réactions) suivies des tags du contenu, et enfin le
/// corps spécifique au type de contenu ([contentBody] : texte, image, lien),
/// suivi des réactions. Un trait gris sépare la signature du contenu ; les
/// réactions se distinguent du contenu par une surface plus claire.
///
/// Statique : l'auteur, la suppression et les réactions observent chacun leur état dans leur propre widget.
class ContentDetailSkeleton extends ConsumerWidget {
  /// Crée un [ContentDetailSkeleton].
  ///
  /// - [title] : titre du contenu, affiché en gras.
  /// - [flair] : flair libre du contenu, sans le `/` initial.
  /// - [signatureId] : identifiant de la signature de l'auteur du contenu, dont le profil est affiché.
  /// - [contentBody] : widget spécifique au type de contenu.
  /// - [createdAt] : date de création du contenu, utilisée pour le temps écoulé.
  /// - [bounce] : nombre de rebonds du contenu, affiché dans les statistiques.
  /// - [tags] : tags du contenu, affichés en chips à la suite des statistiques.
  /// - [onClose] : callback déclenché lors du tap sur le bouton de fermeture.
  /// - [contentId] : identifiant du contenu, utilisé pour sa suppression.
  /// - [isOwned] : `true` si le contenu a été publié par l'utilisateur, qui peut alors le supprimer.
  const ContentDetailSkeleton({
    super.key,
    required this.contentId,
    required this.isOwned,
    required this.title,
    required this.flair,
    required this.signatureId,
    required this.contentBody,
    required this.createdAt,
    required this.bounce,
    required this.tags,
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

  /// Identifiant de la signature de l'auteur du contenu, dont le profil est affiché.
  final String signatureId;

  /// Widget spécifique au type de contenu.
  final Widget contentBody;

  /// Date de création du contenu, utilisée pour le temps écoulé.
  final DateTime createdAt;

  /// Nombre de rebonds du contenu, affiché dans les statistiques.
  final int bounce;

  /// Tags du contenu, affichés en chips à la suite des statistiques.
  final List<Tag> tags;

  /// Callback déclenché lors du tap sur le bouton de fermeture.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // Fond des réactions, en bas de page : il s'étend jusqu'en bas de l'écran
      // même quand les réactions sont peu nombreuses. Le contenu, au-dessus,
      // est posé sur la surface beige.
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: AppColors.background,
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  AppCloseButton(onTap: onClose),
                  const Spacer(),
                  if (isOwned) DeleteContentButton(contentId: contentId, onDeleted: onClose),
                ],
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ColoredBox(
                      color: AppColors.background,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const AppIcon(AppIcons.wifiOff),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: .start,
                                  children: [
                                    AppPrefixedText(prefix: flairPrefix, text: flair, style: AppTextStyles.contentMeta),
                                    ContentDetailAuthor(signatureId: signatureId),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 32, thickness: 1, color: AppColors.border),
                            Text(title, style: AppTextStyles.contentTitle.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              createdAt.timeAgoLong(context.loc),
                              style: AppTextStyles.contentMeta.copyWith(color: AppColors.disabled),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                ContentStats(contentId: contentId, bounce: bounce),
                                for (final tag in tags) AppTag(label: tag.text, colors: tag.flutterColors),
                              ],
                            ),
                            const SizedBox(height: 16),
                            contentBody,
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ContentReactionsSection(contentId: contentId),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
