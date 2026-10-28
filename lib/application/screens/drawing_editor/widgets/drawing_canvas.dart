import 'dart:math';

import 'package:bedbug/application/providers/drawing_rasterizer_provider.dart';
import 'package:bedbug/application/screens/drawing_editor/drawing_editor_image_notifier.dart';
import 'package:bedbug/application/screens/drawing_editor/drawing_editor_notifier.dart';
import 'package:bedbug/application/screens/drawing_editor/drawing_live_stroke_notifier.dart';
import 'package:bedbug/application/screens/drawing_editor/drawing_tool_notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/snackbars/app_snackbar.dart';
import 'package:bedbug/features/content/domain/object_values/drawing.dart';
import 'package:bedbug/features/content/domain/object_values/drawing_operation.dart';
import 'package:bedbug/features/content/domain/object_values/drawing_point.dart';
import 'package:bedbug/features/content/domain/services/stroke_simplification_service.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Générateur des graines des traits : leur seule exigence est de varier d'un trait à l'autre.
final Random _seedRandom = Random();

/// Surface de dessin de l'éditeur, au format 4:3.
///
/// Affiche l'image du dessin, et par-dessus le trait en cours de tracé. Un
/// seul doigt dessine à la fois : les autres sont ignorés. Un trait qui
/// ferait dépasser une limite du dessin est refusé, avec un message.
class DrawingCanvas extends ConsumerWidget {
  /// Crée un [DrawingCanvas].
  ///
  /// - [args] : ouverture de l'éditeur dont le dessin est affiché.
  const DrawingCanvas({super.key, required this.args});

  /// Ouverture de l'éditeur dont le dessin est affiché.
  final DrawingEditorArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AspectRatio(
      aspectRatio: drawingWidth / drawingHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 2)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            return Listener(
              onPointerDown: (event) {
                _onPointerDown(context, ref, event.pointer, _toPoint(event.localPosition, size));
              },
              onPointerMove: (event) {
                ref
                    .read(drawingLiveStrokeNotifierProvider.notifier)
                    .extend(event.pointer, _toPoint(event.localPosition, size));
              },
              onPointerUp: (event) => _onPointerUp(context, ref, event.pointer),
              onPointerCancel: (event) => ref.read(drawingLiveStrokeNotifierProvider.notifier).cancel(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Consumer(
                    builder: (context, ref, _) {
                      final image = ref.watch(drawingEditorImageNotifierProvider(args)).value?.image;
                      if (image == null) {
                        return const ColoredBox(color: AppColors.surface);
                      }
                      return RawImage(image: image, fit: BoxFit.fill, filterQuality: FilterQuality.none);
                    },
                  ),
                  // Seul le trait en cours se redessine au rythme du doigt.
                  Consumer(
                    builder: (context, ref, _) {
                      final liveStroke = ref.watch(drawingLiveStrokeNotifierProvider);
                      final imageRevision = ref.watch(drawingEditorImageNotifierProvider(args)).value?.revision ?? -1;
                      final committedRevision = liveStroke?.committedRevision;
                      if (liveStroke == null || (committedRevision != null && imageRevision >= committedRevision)) {
                        return const SizedBox.shrink();
                      }
                      final tool = ref.watch(drawingToolNotifierProvider);
                      return CustomPaint(
                        painter: _LiveStrokePainter(
                          rasterizer: ref.read(drawingRasterizerProvider),
                          stroke: _buildStroke(tool, liveStroke.points, liveStroke.seed),
                          palette: ref.watch(drawingEditorNotifierProvider(args)).drawing.palette,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Commence un trait, ou applique le pot de peinture, au point touché.
  ///
  /// - [context] : contexte, pour afficher un éventuel refus.
  /// - [ref] : accès aux notifiers de l'éditeur.
  /// - [pointer] : identifiant du doigt.
  /// - [point] : point touché, dans le repère du dessin.
  void _onPointerDown(BuildContext context, WidgetRef ref, int pointer, DrawingPoint point) {
    final liveStroke = ref.read(drawingLiveStrokeNotifierProvider);
    if (liveStroke != null && liveStroke.committedRevision == null) {
      return;
    }
    final tool = ref.read(drawingToolNotifierProvider);
    if (tool.tool != DrawingTool.fill) {
      ref.read(drawingLiveStrokeNotifierProvider.notifier).start(pointer, point, _seedRandom.nextInt(maxDrawingSeed));
      return;
    }
    final fill = DrawingFill(layer: tool.layer, colorIndex: tool.colorIndex, point: point);
    if (!ref.read(drawingEditorNotifierProvider(args).notifier).addOperation(fill)) {
      AppSnackbar.showError(context, context.loc.drawingLimitReached);
    }
  }

  /// Termine le trait du doigt [pointer] et l'ajoute au dessin, simplifié.
  ///
  /// - [context] : contexte, pour afficher un éventuel refus.
  /// - [ref] : accès aux notifiers de l'éditeur.
  /// - [pointer] : identifiant du doigt levé.
  void _onPointerUp(BuildContext context, WidgetRef ref, int pointer) {
    final liveStroke = ref.read(drawingLiveStrokeNotifierProvider);
    if (liveStroke == null || liveStroke.pointer != pointer || liveStroke.committedRevision != null) {
      return;
    }
    final points = ref.read(strokeSimplificationServiceProvider).simplify(liveStroke.points);
    final stroke = _buildStroke(ref.read(drawingToolNotifierProvider), points, liveStroke.seed);
    final editorNotifier = ref.read(drawingEditorNotifierProvider(args).notifier);
    if (!editorNotifier.addOperation(stroke)) {
      ref.read(drawingLiveStrokeNotifierProvider.notifier).cancel();
      AppSnackbar.showError(context, context.loc.drawingLimitReached);
      return;
    }
    ref.read(drawingLiveStrokeNotifierProvider.notifier).commit(ref.read(drawingEditorNotifierProvider(args)).revision);
  }

  /// Retourne le point du dessin sous [position], ramené dans le repère du dessin.
  ///
  /// - [position] : position du doigt dans la surface.
  /// - [size] : taille de la surface.
  DrawingPoint _toPoint(Offset position, Size size) {
    final x = (position.dx / size.width * drawingWidth).round().clamp(0, drawingWidth - 1);
    final y = (position.dy / size.height * drawingHeight).round().clamp(0, drawingHeight - 1);
    return DrawingPoint(x, y);
  }

  /// Retourne le trait passant par [points] avec l'outil [tool].
  ///
  /// - [tool] : outil choisi (jamais le pot de peinture, qui ne trace pas de trait).
  /// - [points] : points du trait.
  /// - [seed] : graine du trait.
  DrawingStroke _buildStroke(DrawingToolState tool, List<DrawingPoint> points, int seed) {
    return DrawingStroke(
      layer: tool.layer,
      colorIndex: tool.colorIndex,
      brush: switch (tool.tool) {
        DrawingTool.pen || DrawingTool.fill => DrawingBrush.pen,
        DrawingTool.marker => DrawingBrush.marker,
        DrawingTool.pencil => DrawingBrush.pencil,
        DrawingTool.spray => DrawingBrush.spray,
        DrawingTool.eraser => DrawingBrush.eraser,
      },
      size: tool.sizeIndex,
      seed: seed,
      points: points,
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
  _LiveStrokePainter({required this.rasterizer, required this.stroke, required this.palette});

  /// Service qui sait dessiner un trait.
  final DrawingRasterizer rasterizer;

  /// Trait en cours.
  final DrawingStroke stroke;

  /// Palette du dessin.
  final List<int> palette;

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
