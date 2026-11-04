import 'package:bedbug/application/screens/drawing_editor/notifiers/drawing_canvas_zoom.notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Place la surface de dessin dans l'écran, à sa taille et sa position zoomées.
///
/// Seule partie de la surface à observer le zoom, qui change au rythme des doigts : le dessin lui est passé tel quel
/// dans [child], et ne se reconstruit pas pendant un geste.
class DrawingCanvasViewport extends ConsumerWidget {
  /// Crée un [DrawingCanvasViewport].
  ///
  /// - [viewport] : taille de l'écran qui montre la surface.
  /// - [fitSize] : taille de la surface ajustée à l'écran, celle du zoom 1.
  /// - [child] : surface de dessin à placer.
  const DrawingCanvasViewport({super.key, required this.viewport, required this.fitSize, required this.child});

  /// Taille de l'écran qui montre la surface.
  final Size viewport;

  /// Taille de la surface ajustée à l'écran, celle du zoom 1.
  final Size fitSize;

  /// Surface de dessin à placer.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoom = ref.watch(drawingCanvasZoomNotifierProvider);
    final origin = zoom.originIn(viewport, fitSize);

    return Stack(
      children: [
        Positioned(
          left: origin.dx,
          top: origin.dy,
          width: fitSize.width * zoom.scale,
          height: fitSize.height * zoom.scale,
          child: child,
        ),
      ],
    );
  }
}
