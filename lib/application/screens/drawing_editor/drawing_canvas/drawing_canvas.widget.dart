import 'dart:math';

import 'package:bedbug/application/screens/drawing_editor/drawing_canvas_image/drawing_canvas_image.widget.dart';
import 'package:bedbug/application/screens/drawing_editor/drawing_canvas_viewport/drawing_canvas_viewport.widget.dart';
import 'package:bedbug/application/screens/drawing_editor/drawing_live_stroke/drawing_live_stroke.notifier.dart';
import 'package:bedbug/application/screens/drawing_editor/drawing_live_stroke/drawing_live_stroke.widget.dart';
import 'package:bedbug/application/screens/drawing_editor/notifiers/drawing_canvas_zoom.notifier.dart';
import 'package:bedbug/application/screens/drawing_editor/notifiers/drawing_editor.notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/snackbars/app_snackbar.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:bedbug/resources/content/drawing/drawing.config.dart';
import 'package:bedbug/resources/content/drawing/drawing.extension.dart';
import 'package:bedbug/resources/content/drawing/drawing.value_object.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Générateur des graines des traits : leur seule exigence est de varier d'un trait à l'autre.
final Random _seedRandom = Random();

/// Marge autour de la surface au zoom 1, en pixels.
const double _kFitMargin = 16;

/// Surface de dessin de l'éditeur, posée sur tout l'écran à sa taille zoomée.
///
/// L'écran entier sert de fenêtre : au zoom 1, la surface y tient tout
/// juste ; dézoomée, elle rétrécit au milieu ; zoomée, elle déborde et
/// remplit l'écran. Elle affiche l'image du dessin, et par-dessus le trait
/// en cours de tracé. Un seul doigt dessine à la fois : les autres sont
/// ignorés, comme un doigt posé hors de la surface. En mode zoom, les doigts
/// ne dessinent plus : ils déplacent et zooment la surface. Un trait qui
/// ferait dépasser une limite du dessin est refusé, avec un message.
///
/// N'observe que les dimensions du dessin : le placement de la surface, l'image et le trait en cours se reconstruisent
/// chacun dans leur propre widget.
class DrawingCanvas extends ConsumerWidget {
  /// Crée un [DrawingCanvas].
  ///
  /// - [args] : ouverture de l'éditeur dont le dessin est affiché.
  const DrawingCanvas({super.key, required this.args});

  /// Ouverture de l'éditeur dont le dessin est affiché.
  final DrawingEditorArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimensions = ref.watch(
      drawingEditorNotifierProvider(args).select((state) => (width: state.drawing.width, height: state.drawing.height)),
    );
    // Au zoom 1, la surface évite les encoches et la barre d'état, avec une marge pour voir ses bords.
    final safePadding = MediaQuery.paddingOf(context) + const EdgeInsets.all(_kFitMargin);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.biggest;
        final fitSize = _fitSize(safePadding.deflateSize(viewport), dimensions);
        return Listener(
          onPointerDown: (event) {
            final point = _toPoint(ref, event.localPosition, viewport, fitSize, dimensions, isClamped: false);
            if (point != null) {
              _onPointerDown(context, ref, event.pointer, point);
            }
          },
          onPointerMove: (event) {
            final point = _toPoint(ref, event.localPosition, viewport, fitSize, dimensions, isClamped: true)!;
            ref.read(drawingLiveStrokeNotifierProvider(args).notifier).extend(event.pointer, point);
          },
          onPointerUp: (event) => _onPointerUp(context, ref, event.pointer),
          onPointerCancel: (event) => ref.read(drawingLiveStrokeNotifierProvider(args).notifier).cancel(),
          child: GestureDetector(
            // Le fond autour de la surface déplace et zoome aussi, en mode zoom.
            behavior: HitTestBehavior.opaque,
            onScaleStart: (details) {
              ref.read(drawingCanvasZoomNotifierProvider.notifier).startGesture(details.localFocalPoint);
            },
            onScaleUpdate: (details) {
              ref
                  .read(drawingCanvasZoomNotifierProvider.notifier)
                  .updateGesture(details.localFocalPoint, details.scale, viewport, fitSize);
            },
            child: DrawingCanvasViewport(
              viewport: viewport,
              fitSize: fitSize,
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(border: Border.all(color: AppColors.disabled)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DrawingCanvasImage(args: args),
                    DrawingLiveStroke(args: args, drawingWidth: dimensions.width),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Retourne la taille de la surface ajustée à [available], aux proportions du dessin : celle du zoom 1.
  ///
  /// - [available] : place disponible, hors encoches et marges.
  /// - [dimensions] : largeur et hauteur du repère du dessin, en points.
  Size _fitSize(Size available, ({int width, int height}) dimensions) {
    final ratio = min(available.width / dimensions.width, available.height / dimensions.height);
    return Size(dimensions.width * ratio, dimensions.height * ratio);
  }

  /// Commence un trait, ou applique le pot de peinture, au point touché, sauf en mode zoom.
  ///
  /// - [context] : contexte, pour afficher un éventuel refus.
  /// - [ref] : accès aux notifiers de l'éditeur.
  /// - [pointer] : identifiant du doigt.
  /// - [point] : point touché, dans le repère du dessin.
  void _onPointerDown(BuildContext context, WidgetRef ref, int pointer, DrawingPoint point) {
    if (ref.read(drawingCanvasZoomNotifierProvider).isZoomMode) {
      return;
    }
    final liveStroke = ref.read(drawingLiveStrokeNotifierProvider(args));
    if (liveStroke != null && liveStroke.committedRevision == null) {
      return;
    }
    final editorState = ref.read(drawingEditorNotifierProvider(args));
    final tool = editorState.tool;
    if (tool.tool != DrawingTool.fill) {
      ref
          .read(drawingLiveStrokeNotifierProvider(args).notifier)
          .start(pointer, point, _seedRandom.nextInt(maxDrawingSeed), tool, editorState.drawing.palette);
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
    final liveStrokeNotifier = ref.read(drawingLiveStrokeNotifierProvider(args).notifier);
    final stroke = liveStrokeNotifier.strokeToCommit(pointer);
    if (stroke == null) {
      return;
    }
    if (!ref.read(drawingEditorNotifierProvider(args).notifier).addOperation(stroke)) {
      liveStrokeNotifier.cancel();
      AppSnackbar.showError(context, context.loc.drawingLimitReached);
      return;
    }
    liveStrokeNotifier.commit(ref.read(drawingEditorNotifierProvider(args)).revision);
  }

  /// Retourne le point du dessin sous [position], zoom compris, dans le repère du dessin.
  ///
  /// Hors de la surface, le point est ramené sur son bord si [isClamped]
  /// (un trait qui déborde longe le bord), et vaut `null` sinon (un doigt
  /// posé à côté ne commence rien).
  ///
  /// - [ref] : accès au zoom de la surface.
  /// - [position] : position du doigt dans l'écran.
  /// - [viewport] : taille de l'écran qui montre la surface.
  /// - [fitSize] : taille de la surface ajustée à l'écran, celle du zoom 1.
  /// - [dimensions] : largeur et hauteur du repère du dessin, en points.
  /// - [isClamped] : `true` pour ramener sur le bord un point hors de la surface.
  DrawingPoint? _toPoint(
    WidgetRef ref,
    Offset position,
    Size viewport,
    Size fitSize,
    ({int width, int height}) dimensions, {
    required bool isClamped,
  }) {
    final zoom = ref.read(drawingCanvasZoomNotifierProvider);
    final local = position - zoom.originIn(viewport, fitSize);
    final x = (local.dx / (fitSize.width * zoom.scale) * dimensions.width).round();
    final y = (local.dy / (fitSize.height * zoom.scale) * dimensions.height).round();
    final isInside = x >= 0 && x < dimensions.width && y >= 0 && y < dimensions.height;
    if (!isInside && !isClamped) {
      return null;
    }
    return DrawingPoint(x.clamp(0, dimensions.width - 1), y.clamp(0, dimensions.height - 1));
  }
}
