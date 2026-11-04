import 'package:bedbug/application/screens/drawing_editor/drawing_editor_menu/drawing_editor_menu.widget.dart';
import 'package:bedbug/application/screens/drawing_editor/notifiers/drawing_editor.notifier.dart';
import 'package:bedbug/application/widgets/buttons/app_gradient_button.widget.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bouton du menu qui valide le dessin : il referme le menu avec [DrawingEditorMenuAction.done].
///
/// Grisé tant que le dessin est vide : il n'y a rien à rendre à la page de création.
class DrawingDoneButton extends ConsumerWidget {
  /// Crée un [DrawingDoneButton].
  ///
  /// - [args] : ouverture de l'éditeur dont le dessin est validé.
  const DrawingDoneButton({super.key, required this.args});

  /// Ouverture de l'éditeur dont le dessin est validé.
  final DrawingEditorArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDrawingEmpty = ref.watch(
      drawingEditorNotifierProvider(args).select((state) => state.drawing.operations.isEmpty),
    );

    return AppGradientButton(
      onTap: isDrawingEmpty ? null : () => Navigator.of(context).pop(DrawingEditorMenuAction.done),
      child: Text(context.loc.drawingDone),
    );
  }
}
