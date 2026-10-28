import 'package:bedbug/application/screens/content_detail/content_detail_skeleton.dart';
import 'package:bedbug/application/widgets/drawing/app_drawing_image.dart';
import 'package:bedbug/features/content/domain/entities/drawing_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Page de détail d'un [DrawingContent].
class DrawingContentDetailScreen extends ConsumerWidget {
  /// Crée un [DrawingContentDetailScreen].
  ///
  /// - [content] : contenu dessiné à afficher en détail.
  const DrawingContentDetailScreen({super.key, required this.content});

  /// Contenu dessiné à afficher en détail.
  final DrawingContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ContentDetailSkeleton(
      contentId: content.id,
      isOwned: content.isOwned,
      title: content.title,
      flair: content.flair,
      authorId: content.authorId,
      createdAt: content.createdAt,
      bounce: content.bounce,
      tags: content.tags,
      onClose: () => context.pop(),
      contentBody: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AppDrawingImage(drawing: content.drawing, cacheKey: content.id),
      ),
    );
  }
}
