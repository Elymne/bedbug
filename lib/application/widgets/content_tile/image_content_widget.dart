import 'package:bedbug/application/widgets/content_tile/content_card_widget.dart';
import 'package:bedbug/features/content/domain/entities/image_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Affiche un [ImageContent] sous forme de carte compacte.
class ImageContentWidget extends ConsumerWidget {
  /// Crée un [ImageContentWidget].
  ///
  /// - [content] : contenu image à afficher.
  const ImageContentWidget({super.key, required this.content});

  /// Contenu image à afficher.
  final ImageContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ContentCardWidget(
      icon: Icons.image_outlined,
      title: content.title ?? content.fileName,
      preview: content.fileName,
    );
  }
}
