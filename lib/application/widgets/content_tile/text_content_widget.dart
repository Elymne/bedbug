import 'package:bedbug/application/style/app_text_styles.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Affiche un [TextContent] sous forme de tuile compacte.
class TextContentWidget extends ConsumerWidget {
  /// Crée un [TextContentWidget].
  ///
  /// - [content] : contenu texte à afficher.
  const TextContentWidget({super.key, required this.content});

  /// Contenu texte à afficher.
  final TextContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTitleSingleLine = _isSingleLine(
          text: content.title,
          style: AppTextStyles.contentTitle,
          maxWidth: constraints.maxWidth,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content.title, style: AppTextStyles.contentTitle, maxLines: 4, overflow: TextOverflow.ellipsis),
            if (isTitleSingleLine)
              Text(content.body, style: AppTextStyles.contentPreview, maxLines: 3, overflow: TextOverflow.fade),
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
