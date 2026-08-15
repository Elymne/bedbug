import 'dart:io';

import 'package:bedbug/application/providers/app_docs_dir_provider.dart';
import 'package:bedbug/application/screens/content_detail/content_detail_skeleton.dart';
import 'package:bedbug/application/style/app_text_styles.dart';
import 'package:bedbug/application/widgets/images/app_file_image.dart';
import 'package:bedbug/application/widgets/texts/app_loading_text.dart';
import 'package:bedbug/features/content/domain/entities/image_content.dart';
import 'package:bedbug/shared/config/content_image_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Page de détail d'un [ImageContent].
class ImageContentDetailScreen extends ConsumerWidget {
  /// Crée un [ImageContentDetailScreen].
  ///
  /// - [content] : contenu image à afficher en détail.
  const ImageContentDetailScreen({super.key, required this.content});

  /// Contenu image à afficher en détail.
  final ImageContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ContentDetailSkeleton(
      title: content.title,
      subId: content.subId,
      createdAt: content.createdAt,
      bounce: content.bounce,
      onClose: () => context.pop(),
      contentBody: _buildContentBody(ref),
    );
  }

  /// Retourne l'image du contenu suivie de sa description optionnelle.
  Widget _buildContentBody(WidgetRef ref) {
    final appDocsDirWatcher = ref.watch(appDocsDirProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        appDocsDirWatcher.when(
          loading: () => const AppLoadingText(),
          error: (error, stack) => const Icon(Icons.broken_image_outlined),
          data: (dir) {
            final file = File('${dir.path}/$contentImagesFolder/${content.fileName}');
            return AppFileImage(file: file, width: double.infinity, height: 250);
          },
        ),
        if (content.body != null) Text(content.body!, style: AppTextStyles.contentPreview),
      ],
    );
  }
}
