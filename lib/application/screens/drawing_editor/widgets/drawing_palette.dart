import 'package:bedbug/application/screens/drawing_editor/drawing_editor_notifier.dart';
import 'package:bedbug/application/screens/drawing_editor/drawing_tool_notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Taille d'une pastille de couleur, en pixels.
const double _kSwatchSize = 32;

/// Palette de l'éditeur de dessin : un tap choisit une couleur, un appui long la change.
///
/// Changer une couleur de la palette recolore tout ce qui a déjà été
/// dessiné avec elle : un dessin garde ses 16 couleurs, mais l'auteur les
/// choisit.
class DrawingPalette extends ConsumerWidget {
  /// Crée une [DrawingPalette].
  ///
  /// - [args] : ouverture de l'éditeur dont la palette est affichée.
  const DrawingPalette({super.key, required this.args});

  /// Ouverture de l'éditeur dont la palette est affichée.
  final DrawingEditorArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;
    final palette = ref.watch(drawingEditorNotifierProvider(args).select((state) => state.drawing.palette));
    final colorIndex = ref.watch(drawingToolNotifierProvider.select((state) => state.colorIndex));

    return Column(
      spacing: 6,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final (index, color) in palette.indexed)
              Semantics(
                button: true,
                selected: index == colorIndex,
                label: l10n.drawingColorLabel(index + 1),
                child: GestureDetector(
                  onTap: () => ref.read(drawingToolNotifierProvider.notifier).setColor(index),
                  onLongPress: () => _editColor(context, ref, index, Color(color)),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: index == colorIndex ? AppColors.primary : AppColors.border,
                        width: index == colorIndex ? 3 : 1,
                      ),
                    ),
                    child: const SizedBox.square(dimension: _kSwatchSize),
                  ),
                ),
              ),
          ],
        ),
        Text(l10n.drawingPaletteHint, style: const TextStyle(fontSize: 12, color: AppColors.disabled)),
      ],
    );
  }

  /// Ouvre le sélecteur de couleur sur [currentColor] et remplace la couleur en position [index] par celle choisie.
  ///
  /// `showColorPickerDialog` renvoie la couleur de départ en cas
  /// d'annulation : rien ne change alors.
  ///
  /// - [context] : contexte du dialog.
  /// - [ref] : accès au notifier de l'éditeur.
  /// - [index] : position de la couleur dans la palette.
  /// - [currentColor] : couleur actuelle.
  Future<void> _editColor(BuildContext context, WidgetRef ref, int index, Color currentColor) async {
    final pickedColor = await showColorPickerDialog(
      context,
      currentColor,
      title: Text(context.loc.drawingColorEditTitle),
      pickersEnabled: const {
        ColorPickerType.wheel: true,
        ColorPickerType.primary: false,
        ColorPickerType.accent: false,
      },
      enableShadesSelection: false,
      enableOpacity: false,
      barrierColor: AppColors.barrier,
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
    );
    if (pickedColor == currentColor) {
      return;
    }
    ref.read(drawingEditorNotifierProvider(args).notifier).setPaletteColor(index, pickedColor.toARGB32());
  }
}
