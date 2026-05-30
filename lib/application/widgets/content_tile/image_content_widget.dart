import 'package:bedbug/application/widgets/tags/app_tag.dart';
import 'package:bedbug/features/content/domain/entities/image_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Taille de l'icône leading.
const double _iconSize = 24;

/// Espacement horizontal entre l'icône et le texte.
const double _iconSpacing = 16;

/// Padding interne de la tuile.
const double _tilePadding = 16;

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
    final titleStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600);
    final title = content.title ?? content.fileName;

    return Padding(
      padding: const EdgeInsets.all(_tilePadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: _iconSpacing,
        children: [
          const Icon(Icons.image_outlined, size: _iconSize),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isTitleSingleLine = _isSingleLine(text: title, style: titleStyle, maxWidth: constraints.maxWidth);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(content.authorId, style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Colors.grey), overflow: TextOverflow.ellipsis),
                    Text(title, style: titleStyle, maxLines: 4, overflow: TextOverflow.ellipsis),
                    if (isTitleSingleLine) Text(content.fileName, maxLines: 3, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    AppTag(label: '${content.bounce} bounces', color: Colors.blueGrey),
                  ],
                );
              },
            ),
          ),
        ],
      ),
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
