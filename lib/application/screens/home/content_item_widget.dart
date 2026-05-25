import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/image_content.dart';
import 'package:bedbug/features/content/domain/entities/link_content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Affiche un item de contenu sous forme de carte compacte.
///
/// Adapte son rendu selon le sous-type concret de [content] :
/// [TextContent], [LinkContent] ou [ImageContent].
class ContentItemWidget extends ConsumerWidget {
  /// Crée un [ContentItemWidget].
  ///
  /// - [content] : contenu à afficher.
  const ContentItemWidget({super.key, required this.content});

  /// Contenu à afficher.
  final Content content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (content is TextContent) {
      final textContent = content as TextContent;
      return _contentCard(
        icon: Icons.article_outlined,
        title: textContent.title,
        preview: textContent.body,
      );
    }
    if (content is LinkContent) {
      final linkContent = content as LinkContent;
      return _contentCard(
        icon: Icons.link,
        title: linkContent.title,
        preview: linkContent.url,
      );
    }
    if (content is ImageContent) {
      final imageContent = content as ImageContent;
      return _contentCard(
        icon: Icons.image_outlined,
        title: imageContent.title ?? imageContent.fileName,
        preview: imageContent.fileName,
      );
    }
    return const SizedBox.shrink();
  }
}

/// Carte compacte affichant une icône, un titre et une ligne de preview.
Widget _contentCard({
  required IconData icon,
  required String title,
  required String preview,
}) {
  return Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
  );
}
