import 'dart:ui' as ui;

import 'package:bedbug/application/drawing/drawing_rasterizer.dart';
import 'package:bedbug/application/screens/drawing_editor/notifiers/drawing_editor.notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [DrawingCanvasImageNotifier], un par ouverture de l'éditeur.
final drawingCanvasImageNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<DrawingCanvasImageNotifier, DrawingCanvasImageState, DrawingEditorArgs>(DrawingCanvasImageNotifier.new);

/// Notifier recalculant l'image du dessin en cours d'édition à chaque modification.
///
/// Ne suit que la révision du dessin : changer d'outil ne recalcule pas l'image. Pendant le calcul, l'image
/// précédente reste disponible (`value` d'un état en cours de rechargement) : le dessin ne clignote pas à chaque
/// trait.
class DrawingCanvasImageNotifier extends AsyncNotifier<DrawingCanvasImageState> {
  /// Crée un [DrawingCanvasImageNotifier].
  ///
  /// - [args] : ouverture de l'éditeur dont l'image est calculée.
  DrawingCanvasImageNotifier(this.args);

  /// Ouverture de l'éditeur dont l'image est calculée.
  final DrawingEditorArgs args;

  /// Service de calcul de l'image d'un dessin.
  late final _drawingRasterizer = ref.read(drawingRasterizerProvider);

  @override
  Future<DrawingCanvasImageState> build() async {
    final revision = ref.watch(drawingEditorNotifierProvider(args).select((state) => state.revision));
    final drawing = ref.read(drawingEditorNotifierProvider(args)).drawing;
    final image = await _drawingRasterizer.render(drawing);
    return DrawingCanvasImageState(image: image, revision: revision);
  }
}

/// Image du dessin en cours d'édition, et la révision du dessin qu'elle montre.
class DrawingCanvasImageState {
  /// Crée un [DrawingCanvasImageState].
  ///
  /// - [image] : image du dessin.
  /// - [revision] : révision du dessin montrée par [image].
  const DrawingCanvasImageState({required this.image, required this.revision});

  /// Image du dessin.
  final ui.Image image;

  /// Révision du dessin montrée par [image].
  final int revision;
}
