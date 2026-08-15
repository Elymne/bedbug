import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_text_styles.dart';
import 'package:bedbug/application/widgets/content_tile/image_content_widget.dart';
import 'package:bedbug/application/widgets/content_tile/link_content_widget.dart';
import 'package:bedbug/application/widgets/content_tile/text_content_widget.dart';
import 'package:bedbug/application/widgets/images/app_round_image.dart';
import 'package:bedbug/application/widgets/tags/app_tag.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/image_content.dart';
import 'package:bedbug/features/content/domain/entities/link_content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/shared/extensions/datetime_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Padding interne commun à tous les contenus.
const double _tilePadding = 16;

/// Dispatcher affichant le widget adapté au type concret de [content].
///
/// Encapsule le header (avatar + sub + temps), le widget spécifique,
/// et la ligne de tags dans une structure commune.
class ContentWidget extends ConsumerWidget {
  /// Contenu à afficher.
  final Content content;

  /// Crée un [ContentWidget].
  ///
  /// - [content] : contenu à afficher.
  const ContentWidget({super.key, required this.content});

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
              Text(
                's/public  •  ${content.createdAt.timeAgo}',
                style: AppTextStyles.contentMeta,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          _buildContent(),
          Row(
            spacing: 8,
            children: [AppTag(label: '${content.bounce} bounces', color: AppColors.primary)],
          ),
        ],
      ),
    );
  }

  /// Retourne le widget spécifique au type de [content].
  Widget _buildContent() {
    if (content is TextContent) return TextContentWidget(content: content as TextContent);
    if (content is LinkContent) return LinkContentWidget(content: content as LinkContent);
    if (content is ImageContent) return ImageContentWidget(content: content as ImageContent);
    return const SizedBox.shrink();
  }
}
