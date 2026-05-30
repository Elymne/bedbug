import 'package:bedbug/application/style/app_text_styles.dart';
import 'package:bedbug/features/content/domain/entities/image_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Affiche un [ImageContent] sous forme de tuile compacte.
class ImageContentWidget extends ConsumerWidget {
  /// Crée un [ImageContentWidget].
  ///
  /// - [content] : contenu image à afficher.
  const ImageContentWidget({super.key, required this.content});

  /// Contenu image à afficher.
  final ImageContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = content.title ?? content.fileName;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTitleSingleLine = _isSingleLine(text: title, style: AppTextStyles.contentTitle, maxWidth: constraints.maxWidth);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.contentTitle, maxLines: 4, overflow: TextOverflow.ellipsis),
            if (isTitleSingleLine) Text(content.fileName, style: AppTextStyles.contentPreview, maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
        );
      },
    );
  }

  /// Retourne `true` si [text] tient sur une seule ligne avec le [style] donné
  /// dans une largeur de [maxWidth].
  bool _isSingleLine({required String text, required TextStyle style, required double maxWidth}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 2,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return !painter.didExceedMaxLines;
  }
}
