import 'package:bedbug/application/screens/drawing_editor/drawing_canvas_image/drawing_canvas_image.notifier.dart';
import 'package:bedbug/application/screens/drawing_editor/notifiers/drawing_editor.notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Image du dessin en cours d'édition, sur la surface de dessin.
///
/// Affichée sans lissage, pour garder le rendu « pixel » des dessins. Une surface blanche la remplace tant que la
/// première image n'est pas calculée.
class DrawingCanvasImage extends ConsumerWidget {
  /// Crée un [DrawingCanvasImage].
  ///
  /// - [args] : ouverture de l'éditeur dont l'image est affichée.
  const DrawingCanvasImage({super.key, required this.args});

  /// Ouverture de l'éditeur dont l'image est affichée.
  final DrawingEditorArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawingCanvasImageNotifierWatcher = ref.watch(drawingCanvasImageNotifierProvider(args));
    final image = drawingCanvasImageNotifierWatcher.value?.image;
    if (image == null) {
      return const ColoredBox(color: AppColors.surface);
    }
    return RawImage(image: image, fit: BoxFit.fill, filterQuality: FilterQuality.none);
  }
}
