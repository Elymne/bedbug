import 'package:bedbug/application/drawing/drawing_rasterizer.dart';
import 'package:bedbug/application/screens/drawing_editor/drawing_live_stroke/drawing_live_stroke.notifier.dart';
import 'package:bedbug/application/screens/drawing_editor/notifiers/drawing_editor.notifier.dart';
import 'package:bedbug/resources/content/drawing/drawing.value_object.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Trait en cours de tracé, dessiné par-dessus l'image du dessin.
///
/// Seule partie de la surface à se redessiner au rythme du doigt. Le trait porte tout ce qu'il faut pour être
/// dessiné (outil et palette du début du tracé) : cette couche n'observe que lui.
class DrawingLiveStroke extends ConsumerWidget {
  /// Crée un [DrawingLiveStroke].
  ///
  /// - [args] : ouverture de l'éditeur dont le trait est affiché.
  /// - [drawingWidth] : largeur du repère du dessin, en points.
  const DrawingLiveStroke({super.key, required this.args, required this.drawingWidth});

  /// Ouverture de l'éditeur dont le trait est affiché.
  final DrawingEditorArgs args;

  /// Largeur du repère du dessin, en points.
  final int drawingWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveStroke = ref.watch(drawingLiveStrokeNotifierProvider(args));
    if (liveStroke == null) {
      return const SizedBox.shrink();
    }
    return CustomPaint(
      painter: _LiveStrokePainter(
        rasterizer: ref.read(drawingRasterizerProvider),
        stroke: liveStroke.stroke,
        palette: liveStroke.palette,
        drawingWidth: drawingWidth,
      ),
    );
  }
}

/// Dessine le trait en cours de tracé, à l'échelle de la surface.
class _LiveStrokePainter extends CustomPainter {
  /// Crée un [_LiveStrokePainter].
  ///
  /// - [rasterizer] : service qui sait dessiner un trait.
  /// - [stroke] : trait en cours.
  /// - [palette] : palette du dessin.
  /// - [drawingWidth] : largeur du repère du dessin, en points.
  _LiveStrokePainter({
    required this.rasterizer,
    required this.stroke,
    required this.palette,
    required this.drawingWidth,
  });

  /// Service qui sait dessiner un trait.
  final DrawingRasterizer rasterizer;

  /// Trait en cours.
  final DrawingStroke stroke;

  /// Palette du dessin.
  final List<int> palette;

  /// Largeur du repère du dessin, en points.
  final int drawingWidth;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..clipRect(Offset.zero & size)
      ..scale(size.width / drawingWidth);
    rasterizer.paintStroke(canvas, stroke, palette, isPreview: true);
  }

  @override
  bool shouldRepaint(_LiveStrokePainter oldDelegate) {
    return oldDelegate.stroke.points.length != stroke.points.length || oldDelegate.stroke != stroke;
  }
}
