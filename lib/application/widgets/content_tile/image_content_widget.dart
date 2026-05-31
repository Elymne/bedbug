import 'dart:io';

import 'package:bedbug/application/providers/app_docs_dir_provider.dart';
import 'package:bedbug/application/style/app_text_styles.dart';
import 'package:bedbug/application/widgets/images/app_file_image.dart';
import 'package:bedbug/application/widgets/texts/app_loading_text.dart';
import 'package:bedbug/features/content/domain/entities/image_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hauteur minimale d'affichage de l'image.
const double _imageMinHeight = 300;

/// Hauteur maximale d'affichage de l'image.
const double _imageMaxHeight = 600;

/// Sous-dossier de stockage des images dans le dossier de documents de l'app.
const String _imageFolder = 'content_images';

/// Affiche un [ImageContent] sous forme de tuile compacte.
///
/// Affiche le titre (2 lignes max) puis l'image en dessous.
class ImageContentWidget extends ConsumerWidget {
  /// Crée un [ImageContentWidget].
  ///
  /// - [content] : contenu image à afficher.
  const ImageContentWidget({super.key, required this.content});

  /// Contenu image à afficher.
  final ImageContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appDocsDirWatcher = ref.watch(appDocsDirProvider);

    return appDocsDirWatcher.when(
      loading: () => const AppLoadingText(),
      error: (error, stack) => const Icon(Icons.broken_image_outlined),
      data: (dir) {
        final file = File('${dir.path}/$_imageFolder/${content.fileName}');
        final title = content.title ?? content.fileName;
        final displayHeight = content.imageHeight.toDouble().clamp(_imageMinHeight, _imageMaxHeight);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(title, style: AppTextStyles.contentTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
            AppFileImage(file: file, width: double.infinity, height: displayHeight),
          ],
        );
      },
    );
  }
}
