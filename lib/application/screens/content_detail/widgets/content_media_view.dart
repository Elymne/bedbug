import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/image_viewer/image_viewer_screen.dart';
import 'package:bedbug/application/widgets/images/app_image_count_badge.dart';
import 'package:bedbug/application/widgets/media/app_remote_media.dart';
import 'package:bedbug/features/content/domain/object_values/content_media.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Hauteur des médias, en fraction de la hauteur de l'écran.
///
/// Les proportions d'un média distant ne sont connues qu'une fois chargé :
/// une hauteur fixe évite que la page saute au chargement.
const double _kHeightFactor = 0.5;

/// Rayon des coins arrondis des médias.
const double _kRadius = 8;

/// Médias d'un contenu sur sa page de détail, en entier, sans recadrage.
///
/// Plusieurs médias sont présentés dans un carrousel horizontal, avec leur
/// position. Une vidéo se lit sur place ; un tap sur une image ou un gif
/// ouvre la visionneuse plein écran sur les images du contenu.
class ContentMediaView extends ConsumerWidget {
  /// Crée un [ContentMediaView].
  ///
  /// - [media] : médias du contenu, dans l'ordre d'affichage.
  const ContentMediaView({super.key, required this.media});

  /// Médias du contenu, dans l'ordre d'affichage.
  final List<ContentMedia> media;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * _kHeightFactor,
      child: PageView(
        children: [
          for (final (index, item) in media.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_kRadius),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      onTap: item.kind == MediaKind.video ? null : () => _openViewer(context, item),
                      child: AppRemoteMedia(media: item, fit: BoxFit.contain, isPlayable: true),
                    ),
                    if (media.length > 1)
                      PositionedDirectional(
                        top: 8,
                        end: 8,
                        child: AppImageCountBadge(label: '${index + 1}/${media.length}'),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Ouvre la visionneuse plein écran sur les images du contenu, à partir de [touched].
  ///
  /// - [context] : contexte depuis lequel naviguer.
  /// - [touched] : média touché.
  void _openViewer(BuildContext context, ContentMedia touched) {
    final images = [
      for (final item in media)
        if (item.kind != MediaKind.video) item,
    ];
    context.push(
      imageViewerPath,
      extra: ImageViewerParams(media: images, initialIndex: images.indexOf(touched)),
    );
  }
}
