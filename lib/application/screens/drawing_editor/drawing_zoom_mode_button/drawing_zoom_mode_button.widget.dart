import 'package:bedbug/application/screens/drawing_editor/drawing_editor.config.dart';
import 'package:bedbug/application/screens/drawing_editor/notifiers/drawing_canvas_zoom.notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/widgets/icons/app_icon.widget.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bouton flottant qui fait passer les doigts du dessin au zoom, et inversement.
///
/// N'observe que le mode : le zoom lui-même change au rythme des doigts sans le reconstruire.
class DrawingZoomModeButton extends ConsumerWidget {
  /// Crée un [DrawingZoomModeButton].
  const DrawingZoomModeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isZoomMode = ref.watch(drawingCanvasZoomNotifierProvider.select((zoom) => zoom.isZoomMode));

    return IconButton(
      onPressed: () => ref.read(drawingCanvasZoomNotifierProvider.notifier).toggleZoomMode(),
      tooltip: context.loc.drawingZoomMode,
      isSelected: isZoomMode,
      style: drawingEditorButtonStyle.copyWith(
        backgroundColor: WidgetStatePropertyAll(isZoomMode ? AppColors.primary : AppColors.surface),
        foregroundColor: WidgetStatePropertyAll(isZoomMode ? AppColors.onDark : AppColors.onLight),
      ),
      icon: const AppIcon(AppIcons.zoomIn),
    );
  }
}
