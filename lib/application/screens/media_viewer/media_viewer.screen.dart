import 'package:bedbug/application/screens/media_viewer/media_viewer_download_button/media_viewer_download_button.widget.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/widgets/icons/app_icon.widget.dart';
import 'package:bedbug/application/widgets/images/app_image_count_badge.widget.dart';
import 'package:bedbug/application/widgets/media/app_remote_media.widget.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:bedbug/resources/content/content/media_content.entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Zoom maximal autorisé dans la visionneuse.
const double _kMaxZoom = 4;

/// Paramètres de la visionneuse, transmis via `extra` à la navigation.
class MediaViewerParams {
  /// Crée des [MediaViewerParams].
  ///
  /// - [media] : médias du contenu, dans l'ordre d'affichage.
  /// - [initialIndex] : position du média à afficher en premier.
  const MediaViewerParams({required this.media, required this.initialIndex});

  /// Médias du contenu, dans l'ordre d'affichage.
  final List<ContentMedia> media;

  /// Position du média à afficher en premier.
  final int initialIndex;
}

/// Visionneuse plein écran des médias d'un contenu, à faire défiler horizontalement.
///
/// Les images sont zoomables, les vidéos se lisent sur place, et le média
/// affiché peut être enregistré dans la galerie. C'est le seul endroit où un
/// média de la greylist apparaît sans flou : l'ouvrir en grand est le geste
/// volontaire qui le dévoile. Les médias passent par [AppRemoteMedia], comme
/// partout ailleurs : un domaine inconnu reste voilé tant qu'il n'a pas été
/// confirmé.
///
/// Page statique : seul le bouton d'enregistrement observe un état. Elle ne garde que le défilement entre les médias.
class MediaViewerScreen extends ConsumerStatefulWidget {
  /// Crée un [MediaViewerScreen].
  ///
  /// - [params] : médias à afficher et position de départ.
  const MediaViewerScreen({super.key, required this.params});

  /// Médias à afficher et position de départ.
  final MediaViewerParams params;

  @override
  ConsumerState<MediaViewerScreen> createState() => _State();
}

class _State extends ConsumerState<MediaViewerScreen> {
  /// Contrôleur du défilement entre les médias, ouvert sur le média touché.
  late final PageController _pageController = PageController(initialPage: widget.params.initialIndex);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.loc;
    final media = widget.params.media;

    return Scaffold(
      backgroundColor: AppColors.onLightDeep,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: media.length,
            itemBuilder: (context, index) {
              final item = AppRemoteMedia(
                media: media[index],
                fit: BoxFit.contain,
                isPlayable: true,
                isGreyRevealed: true,
              );
              return Stack(
                children: [
                  // Le zoom intercepterait les gestes du lecteur vidéo.
                  if (media[index].kind == MediaKind.video) SizedBox.expand(child: item),
                  if (media[index].kind != MediaKind.video)
                    InteractiveViewer(
                      maxScale: _kMaxZoom,
                      child: SizedBox.expand(child: item),
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
            child: Row(
              children: [
                IconButton(
                  onPressed: context.pop,
                  tooltip: l10n.close,
                  icon: const AppIcon(AppIcons.close, color: AppColors.onDark),
                ),
                const Spacer(),
                MediaViewerDownloadButton(
                  currentMediaUrl: () {
                    return media[_pageController.page?.round() ?? widget.params.initialIndex].url;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
