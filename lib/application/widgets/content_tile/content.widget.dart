import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/style/app_text_styles.dart';
import 'package:bedbug/application/style/tag_color_x.dart';
import 'package:bedbug/application/widgets/content_tile/drawing_content.widget.dart';
import 'package:bedbug/application/widgets/content_tile/link_content.widget.dart';
import 'package:bedbug/application/widgets/content_tile/media_content.widget.dart';
import 'package:bedbug/application/widgets/content_tile/text_content.widget.dart';
import 'package:bedbug/application/widgets/ghost/app_ghost_icon.widget.dart';
import 'package:bedbug/application/widgets/signature/app_signature_avatar.widget.dart';
import 'package:bedbug/application/widgets/stats/content_stats.widget.dart';
import 'package:bedbug/application/widgets/tags/app_tag.widget.dart';
import 'package:bedbug/application/widgets/texts/app_prefixed_text.widget.dart';
import 'package:bedbug/core/extensions/datetime_x.dart';
import 'package:bedbug/infra/resources/content/content/content.config.dart';
import 'package:bedbug/infra/resources/content/content/content.entity.dart';
import 'package:bedbug/infra/resources/content/content/content.entity.detailed.dart';
import 'package:bedbug/infra/resources/content/content/drawing_content.entity.dart';
import 'package:bedbug/infra/resources/content/content/link_content.entity.dart';
import 'package:bedbug/infra/resources/content/content/media_content.entity.dart';
import 'package:bedbug/infra/resources/content/content/text_content.entity.dart';
import 'package:bedbug/infra/resources/signature/signature/signature.config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Padding interne commun à tous les contenus.
const double _tilePadding = 16;

/// Côté de l'icône signalant un contenu pas encore vu.
const double _unviewedIconSize = 16;

/// Taille du texte du bedbug de l'auteur, en tête de tuile.
const double _authorAvatarFontSize = 12;

/// Dispatcher affichant le widget adapté au type concret du contenu de [detailed].
///
/// Encapsule le header (bedbug de l'auteur + flair + temps), le widget spécifique,
/// et la ligne des statistiques (rebonds, réactions) suivie du premier tag,
/// dans une structure commune. L'auteur et le nombre de réactions viennent de [detailed], lu avec le contenu par la
/// liste : la tuile ne fait aucune lecture de son côté.
class ContentWidget extends ConsumerWidget {
  /// Crée un [ContentWidget].
  ///
  /// - [detailed] : contenu à afficher, avec son auteur et son nombre de réactions.
  /// - [isUnviewed] : `true` pour signaler un contenu que l'utilisateur n'a pas encore vu.
  const ContentWidget({super.key, required this.detailed, this.isUnviewed = false});

  /// Contenu à afficher, avec son auteur et son nombre de réactions.
  final ContentDetailed detailed;

  /// Indique si le contenu est à signaler comme pas encore vu.
  final bool isUnviewed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = detailed.content;
    // Un contenu anonyme, ou dont la signature n'est pas connue de l'appareil, est présenté comme anonyme.
    final author = detailed.signature ?? anonymousSignature;
    final authorColorArgb = author.colorArgb;

    return Padding(
      padding: const EdgeInsets.all(_tilePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Row(
            spacing: 6,
            children: [
              Semantics(
                label: author.pseudo,
                excludeSemantics: true,
                // Figé dans la liste : des dizaines de bedbugs animés ensemble détourneraient l'œil des contenus.
                child: AppSignatureAvatar(
                  avatarFrames: author.avatarFrames,
                  avatarFrameSpeed: author.avatarFrameSpeed,
                  ghostColor: authorColorArgb == null ? AppColors.primary : Color(authorColorArgb),
                  ghostSpeed: author.ghostSpeed,
                  fontSize: _authorAvatarFontSize,
                  isAnimating: false,
                ),
              ),
              Expanded(
                child: AppPrefixedText(
                  prefix: flairPrefix,
                  text: '${content.flair}  •  ${content.createdAt.timeAgo}',
                  style: AppTextStyles.contentMeta,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isUnviewed)
                // L'icône s'anime à chaque image : sans cette limite, toute la tuile serait redessinée avec elle.
                const RepaintBoundary(
                  child: AppGhostIcon(
                    icon: AppIcons.sparkle,
                    size: _unviewedIconSize,
                    isAnimating: true,
                    speed: 0.6,
                    intensity: 0.6,
                  ),
                ),
            ],
          ),
          _buildContent(content),
          Row(
            spacing: 12,
            children: [
              ContentStats(bounce: content.bounce, reactionCount: detailed.reactionCount),
              // Un seul tag sur une tuile : la place manque pour les afficher tous.
              if (content.tags.isNotEmpty)
                AppTag(label: content.tags.first.text, colors: content.tags.first.flutterColors),
            ],
          ),
        ],
      ),
    );
  }

  /// Retourne le widget spécifique au type de [content].
  ///
  /// - [content] : contenu à afficher.
  Widget _buildContent(Content content) {
    if (content is TextContent) {
      return TextContentWidget(content: content);
    }
    if (content is LinkContent) {
      return LinkContentWidget(content: content);
    }
    if (content is MediaContent) {
      return MediaContentWidget(content: content);
    }
    if (content is DrawingContent) {
      return DrawingContentWidget(content: content);
    }
    return const SizedBox.shrink();
  }
}
