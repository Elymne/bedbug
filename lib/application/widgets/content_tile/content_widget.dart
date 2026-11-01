import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/style/app_prefixes.dart';
import 'package:bedbug/application/style/app_text_styles.dart';
import 'package:bedbug/application/style/tag_color_x.dart';
import 'package:bedbug/application/widgets/content_tile/drawing_content_widget.dart';
import 'package:bedbug/application/widgets/content_tile/link_content_widget.dart';
import 'package:bedbug/application/widgets/content_tile/media_content_widget.dart';
import 'package:bedbug/application/widgets/content_tile/text_content_widget.dart';
import 'package:bedbug/application/widgets/ghost/app_ghost_icon.dart';
import 'package:bedbug/application/widgets/images/app_round_image.dart';
import 'package:bedbug/application/widgets/stats/content_stats.dart';
import 'package:bedbug/application/widgets/tags/app_tag.dart';
import 'package:bedbug/application/widgets/texts/app_prefixed_text.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/drawing_content.dart';
import 'package:bedbug/features/content/domain/entities/link_content.dart';
import 'package:bedbug/features/content/domain/entities/media_content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/shared/extensions/datetime_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Padding interne commun à tous les contenus.
const double _tilePadding = 16;

/// Côté de l'icône signalant un contenu pas encore vu.
const double _unviewedIconSize = 16;

/// Dispatcher affichant le widget adapté au type concret de [content].
///
/// Encapsule le header (avatar + flair + temps), le widget spécifique,
/// et la ligne des statistiques (rebonds, réactions) suivie du premier tag,
/// dans une structure commune.
class ContentWidget extends ConsumerWidget {
  /// Crée un [ContentWidget].
  ///
  /// - [content] : contenu à afficher.
  /// - [isUnviewed] : `true` pour signaler un contenu que l'utilisateur n'a pas encore vu.
  const ContentWidget({super.key, required this.content, this.isUnviewed = false});

  /// Contenu à afficher.
  final Content content;

  /// Indique si le contenu est à signaler comme pas encore vu.
  final bool isUnviewed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(_tilePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Row(
            spacing: 6,
            children: [
              const AppRoundImage(file: null),
              Expanded(
                child: AppPrefixedText(
                  prefix: AppPrefixes.flair,
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
          _buildContent(),
          Row(
            spacing: 12,
            children: [
              ContentStats(contentId: content.id, bounce: content.bounce),
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
  Widget _buildContent() {
    if (content is TextContent) return TextContentWidget(content: content as TextContent);
    if (content is LinkContent) return LinkContentWidget(content: content as LinkContent);
    if (content is MediaContent) return MediaContentWidget(content: content as MediaContent);
    if (content is DrawingContent) return DrawingContentWidget(content: content as DrawingContent);
    return const SizedBox.shrink();
  }
}
