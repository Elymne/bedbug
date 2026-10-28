import 'package:bedbug/application/providers/drawing_image_provider.dart';
import 'package:bedbug/application/widgets/media/app_media_placeholder.dart';
import 'package:bedbug/features/content/domain/object_values/drawing.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dessin affiché au format 4:3, sans lissage, pour garder ses pixels nets.
///
/// Remplit la largeur que lui donne son parent.
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
      aspectRatio: drawingWidth / drawingHeight,
      child: drawingImageWatcher.when(
        loading: () => const AppMediaPlaceholder(icon: Icons.brush_outlined),
        error: (error, stackTrace) {
          return AppMediaPlaceholder(icon: Icons.broken_image_outlined, label: context.loc.mediaUnavailable);
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
