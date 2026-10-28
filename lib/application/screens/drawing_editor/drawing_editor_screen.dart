import 'package:bedbug/application/screens/drawing_editor/drawing_editor_notifier.dart';
import 'package:bedbug/application/screens/drawing_editor/widgets/drawing_canvas.dart';
import 'package:bedbug/application/screens/drawing_editor/widgets/drawing_palette.dart';
import 'package:bedbug/application/screens/drawing_editor/widgets/drawing_toolbar.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/widgets/buttons/app_close_button.dart';
import 'package:bedbug/application/widgets/buttons/app_gradient_button.dart';
import 'package:bedbug/features/content/domain/object_values/drawing.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Éditeur de dessin, en plein écran.
///
/// Retourne le dessin validé à la page qui l'a ouvert (`context.pop`), ou
/// rien si l'utilisateur ferme l'éditeur sans valider.
class DrawingEditorScreen extends ConsumerStatefulWidget {
  /// Crée un [DrawingEditorScreen].
  ///
  /// - [initialDrawing] : dessin à reprendre, vide pour un nouveau dessin.
  const DrawingEditorScreen({super.key, required this.initialDrawing});

  /// Dessin à reprendre, vide pour un nouveau dessin.
  final Drawing initialDrawing;

  @override
  ConsumerState<DrawingEditorScreen> createState() => _State();
}

class _State extends ConsumerState<DrawingEditorScreen> {
  /// Ouverture de l'éditeur : l'historique et l'image du dessin lui sont propres.
  late final DrawingEditorArgs _args = DrawingEditorArgs(widget.initialDrawing);

  @override
  Widget build(BuildContext context) {
    final l10n = context.loc;
    final editorState = ref.watch(drawingEditorNotifierProvider(_args));
    final editorNotifier = drawingEditorNotifierProvider(_args).notifier;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppValues.baseMargin),
              child: Row(
                children: [
                  const AppCloseButton(),
                  const Spacer(),
                  IconButton(
                    onPressed: editorState.past.isEmpty ? null : () => ref.read(editorNotifier).undo(),
                    tooltip: l10n.drawingUndo,
                    icon: const Icon(Icons.undo),
                  ),
                  IconButton(
                    onPressed: editorState.future.isEmpty ? null : () => ref.read(editorNotifier).redo(),
                    tooltip: l10n.drawingRedo,
                    icon: const Icon(Icons.redo),
                  ),
                  IconButton(
                    onPressed: editorState.drawing.operations.isEmpty ? null : () => ref.read(editorNotifier).clear(),
                    tooltip: l10n.drawingClear,
                    icon: const Icon(Icons.delete_sweep_outlined),
                  ),
                  const SizedBox(width: 8),
                  AppGradientButton(
                    onTap: editorState.drawing.operations.isEmpty ? null : () => context.pop(editorState.drawing),
                    child: Text(l10n.drawingDone),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppValues.baseMargin),
              child: DrawingCanvas(args: _args),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppValues.baseMargin),
                child: Column(
                  spacing: 16,
                  children: [
                    const DrawingToolbar(),
                    DrawingPalette(args: _args),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
