import 'package:bedbug/application/style/app_text_styles.dart';
import 'package:bedbug/application/widgets/drawing/app_drawing_image.dart';
import 'package:bedbug/features/content/domain/entities/drawing_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rayon des coins arrondis du dessin.
const double _kRadius = 8;

/// Affiche un [DrawingContent] sous forme de tuile compacte : le titre, puis le dessin en entier.
class DrawingContentWidget extends ConsumerWidget {
  /// Crée un [DrawingContentWidget].
  ///
  /// - [content] : contenu dessiné à afficher.
  const DrawingContentWidget({super.key, required this.content});

  /// Contenu dessiné à afficher.
  final DrawingContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(content.title, style: AppTextStyles.contentTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        ClipRRect(
          borderRadius: BorderRadius.circular(_kRadius),
          child: AppDrawingImage(drawing: content.drawing, cacheKey: content.id),
        ),
      ],
    );
  }
}
