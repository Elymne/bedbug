import 'dart:io';

import 'package:bedbug/application/screens/image_viewer/save_image_to_gallery_notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/images/app_image_count_badge.dart';
import 'package:bedbug/application/widgets/snackbars/app_snackbar.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Zoom maximal autorisé dans la visionneuse.
const double _kMaxZoom = 4;

/// Paramètres de la visionneuse, transmis via `extra` à la navigation.
class ImageViewerParams {
  /// Crée des [ImageViewerParams].
  ///
  /// - [filePaths] : chemins absolus des images du contenu, dans l'ordre d'affichage.
  /// - [initialIndex] : position de l'image à afficher en premier.
  const ImageViewerParams({required this.filePaths, required this.initialIndex});

  /// Chemins absolus des images du contenu, dans l'ordre d'affichage.
  final List<String> filePaths;

  /// Position de l'image à afficher en premier.
  final int initialIndex;
}

/// Visionneuse plein écran des images d'un contenu.
///
/// Chaque image est affichée en entier sur fond sombre et peut être agrandie
/// au pincement ; on passe de l'une à l'autre en glissant horizontalement.
/// Une croix en haut à gauche ferme la visionneuse, un bouton en haut à
/// droite enregistre l'image affichée dans la galerie du téléphone.
class ImageViewerScreen extends ConsumerStatefulWidget {
  /// Crée un [ImageViewerScreen].
  ///
  /// - [params] : images à afficher et position de départ.
  const ImageViewerScreen({super.key, required this.params});

  /// Images à afficher et position de départ.
  final ImageViewerParams params;

  @override
  ConsumerState<ImageViewerScreen> createState() => _State();
}

class _State extends ConsumerState<ImageViewerScreen> {
  /// Controller du défilement entre les images, ouvert sur l'image touchée.
  late final PageController _pageController = PageController(initialPage: widget.params.initialIndex);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.loc;
    final saveImageToGalleryNotifierWatcher = ref.watch(saveImageToGalleryNotifierProvider);
    final filePaths = widget.params.filePaths;

    return Scaffold(
      backgroundColor: AppColors.onLightDeep,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: filePaths.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  InteractiveViewer(
                    maxScale: _kMaxZoom,
                    child: Center(child: Image.file(File(filePaths[index]), fit: BoxFit.contain)),
                  ),
                  if (filePaths.length > 1)
                    Positioned(
                      bottom: 32,
                      left: 0,
                      right: 0,
                      child: Center(child: AppImageCountBadge(label: '${index + 1}/${filePaths.length}')),
                    ),
                ],
              );
            },
          ),
          SafeArea(
            child: Row(
              children: [
                IconButton(
                  onPressed: context.pop,
                  tooltip: l10n.close,
                  icon: const Icon(Icons.close_rounded, color: AppColors.onDark),
                ),
                const Spacer(),
                IconButton(
                  onPressed: saveImageToGalleryNotifierWatcher.isLoading ? null : _download,
                  tooltip: l10n.imageViewerDownload,
                  icon: const Icon(Icons.download_rounded, color: AppColors.onDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Enregistre l'image affichée dans la galerie du téléphone, puis confirme ou affiche l'erreur.
  Future<void> _download() async {
    final pageIndex = _pageController.page?.round() ?? widget.params.initialIndex;
    final failureMessage = await ref
        .read(saveImageToGalleryNotifierProvider.notifier)
        .save(widget.params.filePaths[pageIndex]);
    if (!mounted) {
      return;
    }
    if (failureMessage != null) {
      AppSnackbar.showError(context, failureMessage);
      return;
    }
    AppSnackbar.showSuccess(context, context.loc.imageViewerSaveSuccess);
  }
}
