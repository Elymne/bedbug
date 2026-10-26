import 'dart:io';

import 'package:bedbug/application/providers/app_docs_dir_provider.dart';
import 'package:bedbug/application/screens/content_detail/content_detail_skeleton.dart';
import 'package:bedbug/application/style/app_text_styles.dart';
import 'package:bedbug/application/widgets/images/app_file_image.dart';
import 'package:bedbug/application/widgets/images/app_image_count_badge.dart';
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
      contentId: content.id,
      isOwned: content.isOwned,
      title: content.title,
      flair: content.flair,
      authorId: content.authorId,
      createdAt: content.createdAt,
      bounce: content.bounce,
      tags: content.tags,
      onClose: () => context.pop(),
      contentBody: _buildContentBody(ref),
    );
  }

  /// Retourne les images du contenu suivies de sa description optionnelle.
  ///
  /// Plusieurs images sont présentées dans un carrousel horizontal, chacune
  /// portant sa position dans la série, pour garder la description visible
  /// sans avoir à faire défiler toutes les images.
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
            final files = [
              for (final image in content.images) File('${dir.path}/$contentImagesFolder/${image.fileName}'),
            ];
            if (files.length == 1) {
              return AppFileImage(file: files.single, width: double.infinity, height: 250);
            }
            return SizedBox(
              height: 250,
              child: PageView(
                children: [
                  for (final (index, file) in files.indexed)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Stack(
                        children: [
                          AppFileImage(file: file, width: double.infinity, height: 250),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: AppImageCountBadge(label: '${index + 1}/${files.length}'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        if (content.body != null) Text(content.body!, style: AppTextStyles.contentPreview),
      ],
    );
  }
}
