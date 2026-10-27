import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/images/app_image_count_badge.dart';
import 'package:bedbug/application/widgets/media/app_remote_media.dart';
import 'package:bedbug/features/content/domain/object_values/content_media.dart';
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
  /// - [media] : images et gifs du contenu, dans l'ordre d'affichage.
  /// - [initialIndex] : position de l'image à afficher en premier.
  const ImageViewerParams({required this.media, required this.initialIndex});

  /// Images et gifs du contenu, dans l'ordre d'affichage.
  final List<ContentMedia> media;

  /// Position de l'image à afficher en premier.
  final int initialIndex;
}

/// Visionneuse plein écran des images d'un contenu, zoomables, à faire défiler horizontalement.
///
/// Les images passent par [AppRemoteMedia], comme partout ailleurs : la
/// visionneuse n'ouvre aucune porte que la page de détail aurait fermée.
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
  /// Contrôleur du défilement entre les images, ouvert sur l'image touchée.
  late final PageController _pageController = PageController(initialPage: widget.params.initialIndex);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.params.media;

    return Scaffold(
      backgroundColor: AppColors.onLightDeep,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: media.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  InteractiveViewer(
                    maxScale: _kMaxZoom,
                    child: SizedBox.expand(
                      child: AppRemoteMedia(media: media[index], fit: BoxFit.contain),
                    ),
                  ),
                  if (media.length > 1)
                    PositionedDirectional(
                      bottom: 32,
                      start: 0,
                      end: 0,
                      child: Center(child: AppImageCountBadge(label: '${index + 1}/${media.length}')),
                    ),
                ],
              );
            },
          ),
          SafeArea(
            child: IconButton(
              onPressed: context.pop,
              tooltip: context.loc.close,
              icon: const Icon(Icons.close_rounded, color: AppColors.onDark),
            ),
          ),
        ],
      ),
    );
  }
}
