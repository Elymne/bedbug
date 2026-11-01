import 'package:bedbug/application/screens/drawing_editor/drawing_tool_notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_icons.dart';

import 'package:bedbug/application/widgets/icons/app_icon.dart';
import 'package:bedbug/features/content/domain/object_values/drawing.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Icône de chaque outil de l'éditeur.
const Map<DrawingTool, AppIcons> _kToolIcons = {
  DrawingTool.pen: AppIcons.edit,
  DrawingTool.marker: AppIcons.brush,
  DrawingTool.pencil: AppIcons.pen,
  DrawingTool.spray: AppIcons.blur,
  DrawingTool.eraser: AppIcons.eraser,
  DrawingTool.fill: AppIcons.fill,
};

/// Diamètre affiché de chaque taille de pinceau, en pixels.
const List<double> _kSizeDots = [6, 10, 16, 24];

/// Barre d'outils de l'éditeur de dessin : outil, taille du pinceau et calque.
class DrawingToolbar extends ConsumerWidget {
  /// Crée une [DrawingToolbar].
  const DrawingToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;
    final toolState = ref.watch(drawingToolNotifierProvider);
    final toolLabels = {
      DrawingTool.pen: l10n.drawingToolPen,
      DrawingTool.marker: l10n.drawingToolMarker,
      DrawingTool.pencil: l10n.drawingToolPencil,
      DrawingTool.spray: l10n.drawingToolSpray,
      DrawingTool.eraser: l10n.drawingToolEraser,
      DrawingTool.fill: l10n.drawingToolFill,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          children: [
            for (final tool in DrawingTool.values)
              IconButton(
                onPressed: () => ref.read(drawingToolNotifierProvider.notifier).setTool(tool),
                tooltip: toolLabels[tool],
                isSelected: tool == toolState.tool,
                style: IconButton.styleFrom(
                  backgroundColor: tool == toolState.tool ? AppColors.primary : AppColors.backgroundLight,
                  foregroundColor: tool == toolState.tool ? AppColors.onDark : AppColors.onLight,
                ),
                icon: AppIcon(_kToolIcons[tool]!),
              ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 12,
          children: [
            for (final (index, dot) in _kSizeDots.indexed)
              Semantics(
                button: true,
                selected: index == toolState.sizeIndex,
                label: l10n.drawingSizeLabel(index + 1),
                child: GestureDetector(
                  onTap: () => ref.read(drawingToolNotifierProvider.notifier).setSize(index),
                  child: SizedBox.square(
                    dimension: 36,
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == toolState.sizeIndex ? AppColors.primary : AppColors.onLight,
                        ),
                        child: SizedBox.square(dimension: dot),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            const AppIcon(AppIcons.layers, color: AppColors.onLight),
            // Du calque du dessus au fond, dans l'ordre où on les voit empilés.
            for (var layer = drawingLayerCount - 1; layer >= 0; layer--)
              ChoiceChip(
                label: Text(l10n.drawingLayerLabel(layer + 1)),
                selected: layer == toolState.layer,
                onSelected: (_) => ref.read(drawingToolNotifierProvider.notifier).setLayer(layer),
              ),
          ],
        ),
      ],
    );
  }
}
