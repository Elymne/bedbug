import 'package:bedbug/application/providers/drawing_image_provider.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/widgets/media/app_media_placeholder.dart';
import 'package:bedbug/features/content/domain/extensions/drawing_dimensions_extension.dart';
import 'package:bedbug/features/content/domain/object_values/drawing.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dessin affiché à ses proportions, sans lissage, pour garder ses pixels nets.
///
/// Remplit la largeur que lui donne son parent, ou sa hauteur si elle est bornée et ne suffit pas.
class AppDrawingImage extends ConsumerWidget {
  /// Crée un [AppDrawingImage].
  ///
  /// - [drawing] : dessin à afficher.
  /// - [cacheKey] : clé de l'image calculée (identifiant du contenu), à changer dès que le dessin change.
  const AppDrawingImage({super.key, required this.drawing, required this.cacheKey});

  /// Dessin à afficher.
  final Drawing drawing;

  /// Clé de l'image calculée.
  final String cacheKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawingImageWatcher = ref.watch(drawingImageProvider(DrawingImageRequest(key: cacheKey, drawing: drawing)));

    return AspectRatio(
      aspectRatio: drawing.width / drawing.height,
      child: drawingImageWatcher.when(
        loading: () => const AppMediaPlaceholder(icon: AppIcons.brush),
        error: (error, stackTrace) {
          return AppMediaPlaceholder(icon: AppIcons.brokenImage, label: context.loc.mediaUnavailable);
        },
        data: (image) {
          return Semantics(
            image: true,
            label: context.loc.drawingSemanticsLabel,
            child: RawImage(image: image, fit: BoxFit.fill, filterQuality: FilterQuality.none),
          );
        },
      ),
    );
  }
}
