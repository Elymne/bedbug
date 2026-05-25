import 'package:bedbug/application/widgets/content_tile/image_content_widget.dart';
import 'package:bedbug/application/widgets/content_tile/link_content_widget.dart';
import 'package:bedbug/application/widgets/content_tile/text_content_widget.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/image_content.dart';
import 'package:bedbug/features/content/domain/entities/link_content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dispatcher affichant le widget adapté au type concret de [content].
///
/// - [TextContent] → [TextContentWidget]
/// - [LinkContent] → [LinkContentWidget]
/// - [ImageContent] → [ImageContentWidget]
class ContentWidget extends ConsumerWidget {
  /// Crée un [ContentWidget].
  ///
  /// - [content] : contenu à afficher.
  const ContentWidget({super.key, required this.content});

  /// Contenu à afficher.
  final Content content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (content is TextContent) return TextContentWidget(content: content as TextContent);
    if (content is LinkContent) return LinkContentWidget(content: content as LinkContent);
    if (content is ImageContent) return ImageContentWidget(content: content as ImageContent);
    return const SizedBox.shrink();
  }
}
