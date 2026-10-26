import 'dart:io';
import 'dart:math';

import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/image_viewer/image_viewer_screen.dart';
import 'package:bedbug/application/widgets/images/app_file_image.dart';
import 'package:bedbug/application/widgets/images/app_image_count_badge.dart';
import 'package:bedbug/features/content/domain/object_values/content_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Hauteur maximale des images, en fraction de la hauteur de l'écran.
///
/// Une image très haute (capture d'écran, affiche) est réduite pour tenir
/// dans cette hauteur, sans jamais être recadrée.
const double _kMaxHeightFactor = 0.7;

/// Images d'un contenu sur sa page de détail, affichées en entier, sans recadrage.
///
/// Une image seule garde ses proportions. Plusieurs images sont présentées
/// dans un carrousel horizontal dont la hauteur s'adapte à la plus haute :
/// les autres y sont affichées entières, centrées, à leurs propres
/// proportions. La bordure arrondie épouse toujours l'image elle-même. Un tap ouvre la
/// visionneuse plein écran sur l'image touchée.
class ContentImagesView extends ConsumerWidget {
  /// Crée un [ContentImagesView].
  ///
  /// - [images] : images du contenu, dans l'ordre d'affichage.
  /// - [files] : fichiers des images, alignés sur [images].
  const ContentImagesView({super.key, required this.images, required this.files});

  /// Images du contenu, dans l'ordre d'affichage.
  final List<ContentImage> images;

  /// Fichiers des images, alignés sur [images].
  final List<File> files;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxHeight = MediaQuery.sizeOf(context).height * _kMaxHeightFactor;
    if (files.length == 1) {
      // Les proportions de l'image, bornées en hauteur : une image très haute
      // est réduite (et centrée) plutôt que de s'étirer sur plusieurs écrans.
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: AspectRatio(
            aspectRatio: images.single.width / images.single.height,
            child: GestureDetector(
              onTap: () => _openViewer(context, 0),
              child: AppFileImage(
                file: files.single,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      );
    }

    final tallestRatio = images.map((image) => image.height / image.width).reduce(max);

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = min(constraints.maxWidth * tallestRatio, maxHeight);
        return SizedBox(
          height: height,
          child: PageView(
            children: [
              for (final (index, file) in files.indexed)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  // Chaque image à ses propres proportions, centrée dans la page :
                  // la bordure et les coins arrondis épousent l'image elle-même.
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: images[index].width / images[index].height,
                      child: GestureDetector(
                        onTap: () => _openViewer(context, index),
                        child: Stack(
                          children: [
                            AppFileImage(
                              file: file,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.contain,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: AppImageCountBadge(label: '${index + 1}/${files.length}'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Ouvre la visionneuse plein écran sur l'image d'index [index].
  ///
  /// - [context] : contexte depuis lequel naviguer.
  /// - [index] : position de l'image touchée.
  void _openViewer(BuildContext context, int index) {
    context.push(
      imageViewerPath,
      extra: ImageViewerParams(filePaths: [for (final file in files) file.path], initialIndex: index),
    );
  }
}
