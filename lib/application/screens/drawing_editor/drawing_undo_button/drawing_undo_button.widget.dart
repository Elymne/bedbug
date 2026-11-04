import 'package:bedbug/application/screens/drawing_editor/drawing_editor.config.dart';
import 'package:bedbug/application/screens/drawing_editor/notifiers/drawing_editor.notifier.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/widgets/icons/app_icon.widget.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bouton flottant qui annule la dernière modification du dessin, le geste le plus fréquent.
///
/// Grisé tant qu'il n'y a rien à annuler.
class DrawingUndoButton extends ConsumerWidget {
  /// Crée un [DrawingUndoButton].
  ///
  /// - [args] : ouverture de l'éditeur dont le dessin est annulé.
  const DrawingUndoButton({super.key, required this.args});

  /// Ouverture de l'éditeur dont le dessin est annulé.
  final DrawingEditorArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canUndo = ref.watch(drawingEditorNotifierProvider(args).select((state) => state.past.isNotEmpty));

    return IconButton(
      onPressed: canUndo ? () => ref.read(drawingEditorNotifierProvider(args).notifier).undo() : null,
      tooltip: context.loc.drawingUndo,
      style: drawingEditorButtonStyle,
      icon: const AppIcon(AppIcons.undo),
    );
  }
}
