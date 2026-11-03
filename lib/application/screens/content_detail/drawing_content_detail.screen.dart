import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/content_detail/content_detail_skeleton.widget.dart';
import 'package:bedbug/application/screens/drawing_viewer/drawing_viewer.screen.dart';
import 'package:bedbug/application/widgets/drawing/app_drawing_image.widget.dart';
import 'package:bedbug/resources/content/content/drawing_content.entity.dart';
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
      signatureId: content.signatureId,
      createdAt: content.createdAt,
      bounce: content.bounce,
      tags: content.tags,
      onClose: () => context.pop(),
      // Toucher le dessin l'ouvre en grand, pour zoomer dedans.
      contentBody: GestureDetector(
        onTap: () {
          context.push(
            drawingViewerPath,
            extra: DrawingViewerParams(drawing: content.drawing, cacheKey: content.id),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AppDrawingImage(drawing: content.drawing, cacheKey: content.id),
        ),
      ),
    );
  }
}
