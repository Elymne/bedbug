import 'package:bedbug/application/screens/content_detail/content_detail_skeleton.dart';
import 'package:bedbug/application/screens/content_detail/widgets/content_media_view.dart';
import 'package:bedbug/application/style/app_text_styles.dart';
import 'package:bedbug/features/content/domain/entities/media_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Page de détail d'un [MediaContent].
class MediaContentDetailScreen extends ConsumerWidget {
  /// Crée un [MediaContentDetailScreen].
  ///
  /// - [content] : contenu média à afficher en détail.
  const MediaContentDetailScreen({super.key, required this.content});

  /// Contenu média à afficher en détail.
  final MediaContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ContentDetailSkeleton(
      contentId: content.id,
      isOwned: content.isOwned,
      title: content.title,
      flair: content.flair,
      signatureId: content.signatureId,
      createdAt: content.createdAt,
      bounce: content.bounce,
      tags: content.tags,
      onClose: () => context.pop(),
      contentBody: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          ContentMediaView(media: content.media),
          if (content.body != null) Text(content.body!, style: AppTextStyles.contentPreview),
        ],
      ),
    );
  }
}
