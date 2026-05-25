import 'package:bedbug/application/widgets/content_tile/content_card_widget.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Affiche un [TextContent] sous forme de carte compacte.
class TextContentWidget extends ConsumerWidget {
  /// Crée un [TextContentWidget].
  ///
  /// - [content] : contenu texte à afficher.
  const TextContentWidget({super.key, required this.content});

  /// Contenu texte à afficher.
  final TextContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ContentCardWidget(
      icon: Icons.article_outlined,
      title: content.title,
      preview: content.body,
    );
  }
}
