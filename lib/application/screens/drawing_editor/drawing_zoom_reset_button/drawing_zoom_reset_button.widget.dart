import 'package:bedbug/application/screens/drawing_editor/notifiers/drawing_canvas_zoom.notifier.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/widgets/icons/app_icon.widget.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bouton du menu qui ramène la surface au zoom 1, ajustée à l'écran.
///
/// Grisé tant que la surface n'est pas zoomée.
class DrawingZoomResetButton extends ConsumerWidget {
  /// Crée un [DrawingZoomResetButton].
  const DrawingZoomResetButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isZoomed = ref.watch(drawingCanvasZoomNotifierProvider.select((zoom) => zoom.scale != 1));

    return IconButton(
      onPressed: isZoomed ? () => ref.read(drawingCanvasZoomNotifierProvider.notifier).reset() : null,
      tooltip: context.loc.drawingZoomReset,
      icon: const AppIcon(AppIcons.fitScreen),
    );
  }
}
