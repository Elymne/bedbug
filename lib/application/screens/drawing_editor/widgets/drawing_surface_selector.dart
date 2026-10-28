import 'package:bedbug/application/screens/drawing_editor/drawing_editor_notifier.dart';
import 'package:bedbug/features/content/domain/object_values/drawing.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Icône de chaque orientation de la surface.
const Map<DrawingOrientation, IconData> _kOrientationIcons = {
  DrawingOrientation.landscape: Icons.crop_landscape,
  DrawingOrientation.portrait: Icons.crop_portrait,
};

/// Choix de la surface de dessin, sa taille et son orientation, possible tant que rien n'a été dessiné.
///
/// Toujours affiché, même désactivé : le faire disparaître au premier trait
/// redimensionnerait la surface sous le doigt.
class DrawingSurfaceSelector extends ConsumerWidget {
  /// Crée un [DrawingSurfaceSelector].
  ///
  /// - [args] : ouverture de l'éditeur dont la surface est choisie.
  const DrawingSurfaceSelector({super.key, required this.args});

  /// Ouverture de l'éditeur dont la surface est choisie.
  final DrawingEditorArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;
    final drawing = ref.watch(drawingEditorNotifierProvider(args)).drawing;
    final sizeLabels = {
      DrawingSize.small: l10n.drawingSurfaceSmall,
      DrawingSize.medium: l10n.drawingSurfaceMedium,
      DrawingSize.large: l10n.drawingSurfaceLarge,
    };
    final orientationLabels = {
      DrawingOrientation.landscape: l10n.drawingOrientationLandscape,
      DrawingOrientation.portrait: l10n.drawingOrientationPortrait,
    };
    final isSurfaceLocked = drawing.operations.isNotEmpty;

    /// Choisit la taille [size] pour la surface.
    void selectSize(DrawingSize size) {
      ref.read(drawingEditorNotifierProvider(args).notifier).setSize(size);
    }

    /// Choisit l'orientation [orientation] pour la surface.
    void selectOrientation(DrawingOrientation orientation) {
      ref.read(drawingEditorNotifierProvider(args).notifier).setOrientation(orientation);
    }

    return Column(
      spacing: 8,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            for (final size in DrawingSize.values)
              ChoiceChip(
                label: Text(sizeLabels[size]!),
                selected: size == drawing.size,
                onSelected: isSurfaceLocked ? null : (_) => selectSize(size),
              ),
          ],
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            for (final orientation in DrawingOrientation.values)
              ChoiceChip(
                avatar: Icon(_kOrientationIcons[orientation]),
                label: Text(orientationLabels[orientation]!),
                selected: orientation == drawing.orientation,
                onSelected: isSurfaceLocked ? null : (_) => selectOrientation(orientation),
              ),
          ],
        ),
      ],
    );
  }
}
