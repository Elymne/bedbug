import 'package:bedbug/application/screens/content_detail/content_detail_skeleton.dart';
import 'package:bedbug/application/style/app_text_styles.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Page de détail d'un [TextContent].
class TextContentDetailScreen extends ConsumerWidget {
  /// Crée un [TextContentDetailScreen].
  ///
  /// - [content] : contenu texte à afficher en détail.
  const TextContentDetailScreen({super.key, required this.content});

  /// Contenu texte à afficher en détail.
  final TextContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ContentDetailSkeleton(
      title: content.title,
      subId: content.subId,
      createdAt: content.createdAt,
      bounce: content.bounce,
      onClose: () => context.pop(),
      contentBody: Text(content.body, style: AppTextStyles.contentPreview),
    );
  }
}
