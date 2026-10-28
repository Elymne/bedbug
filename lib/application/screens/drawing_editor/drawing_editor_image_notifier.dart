import 'dart:ui' as ui;

import 'package:bedbug/application/providers/drawing_rasterizer_provider.dart';
import 'package:bedbug/application/screens/drawing_editor/drawing_editor_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [DrawingEditorImageNotifier], un par ouverture de l'éditeur.
final drawingEditorImageNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<DrawingEditorImageNotifier, DrawingEditorImage, DrawingEditorArgs>(DrawingEditorImageNotifier.new);

/// Notifier recalculant l'image du dessin en cours d'édition à chaque modification.
///
/// Pendant le calcul, l'image précédente reste disponible (`value` d'un état
/// en cours de rechargement) : le dessin ne clignote pas à chaque trait.
class DrawingEditorImageNotifier extends AsyncNotifier<DrawingEditorImage> {
  /// Crée un [DrawingEditorImageNotifier].
  ///
  /// - [args] : ouverture de l'éditeur dont l'image est calculée.
  DrawingEditorImageNotifier(this.args);

  /// Ouverture de l'éditeur dont l'image est calculée.
  final DrawingEditorArgs args;

  /// Service de calcul de l'image d'un dessin.
  late final _drawingRasterizer = ref.read(drawingRasterizerProvider);

  @override
  Future<DrawingEditorImage> build() async {
    final editorState = ref.watch(drawingEditorNotifierProvider(args));
    final image = await _drawingRasterizer.render(editorState.drawing);
    return DrawingEditorImage(image: image, revision: editorState.revision);
  }
}

/// Image du dessin en cours d'édition, et la révision du dessin qu'elle montre.
class DrawingEditorImage {
  /// Crée une [DrawingEditorImage].
  ///
  /// - [image] : image du dessin.
  /// - [revision] : révision du dessin montrée par [image].
  const DrawingEditorImage({required this.image, required this.revision});

  /// Image du dessin.
  final ui.Image image;

  /// Révision du dessin montrée par [image].
  final int revision;
}
