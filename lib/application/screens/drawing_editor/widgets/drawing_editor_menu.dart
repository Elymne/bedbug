import 'package:bedbug/application/screens/drawing_editor/drawing_canvas_zoom_notifier.dart';
import 'package:bedbug/application/screens/drawing_editor/drawing_editor_notifier.dart';
import 'package:bedbug/application/screens/drawing_editor/widgets/drawing_palette.dart';
import 'package:bedbug/application/screens/drawing_editor/widgets/drawing_toolbar.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/widgets/buttons/app_gradient_button.dart';
import 'package:bedbug/application/widgets/icons/app_icon.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Action du menu de l'éditeur qui demande de quitter l'éditeur, transmise à la fermeture du menu.
enum DrawingEditorMenuAction {
  /// Fermer l'éditeur sans garder le dessin.
  close,

  /// Valider le dessin et quitter l'éditeur.
  done,
}

/// Menu de l'éditeur de dessin, ouvert par-dessus la surface : outils, gomme, tailles, calques, couleurs et actions.
///
/// Tout ce qui n'est pas indispensable en dessinant est rangé ici, pour
/// laisser l'écran entier à la surface. Les réglages s'appliquent aussitôt ;
/// fermer ou valider l'éditeur referme le menu avec l'action choisie
/// ([DrawingEditorMenuAction]), que l'éditeur exécute.
class DrawingEditorMenu extends ConsumerWidget {
  /// Crée un [DrawingEditorMenu].
  ///
  /// - [args] : ouverture de l'éditeur dont le menu règle les outils.
  const DrawingEditorMenu({super.key, required this.args});

  /// Ouverture de l'éditeur dont le menu règle les outils.
  final DrawingEditorArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;
    final editorState = ref.watch(drawingEditorNotifierProvider(args));
    final editorNotifier = drawingEditorNotifierProvider(args).notifier;
    final isZoomed = ref.watch(drawingCanvasZoomNotifierProvider.select((zoom) => zoom.scale != 1));
    final isDrawingEmpty = editorState.drawing.operations.isEmpty;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppValues.baseMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(DrawingEditorMenuAction.close),
                  tooltip: l10n.close,
                  icon: const AppIcon(AppIcons.close),
                ),
                const Spacer(),
                IconButton(
                  onPressed: editorState.future.isEmpty ? null : () => ref.read(editorNotifier).redo(),
                  tooltip: l10n.drawingRedo,
                  icon: const AppIcon(AppIcons.redo),
                ),
                IconButton(
                  onPressed: isDrawingEmpty ? null : () => ref.read(editorNotifier).clear(),
                  tooltip: l10n.drawingClear,
                  icon: const AppIcon(AppIcons.deleteAll),
                ),
                IconButton(
                  onPressed: isZoomed ? () => ref.read(drawingCanvasZoomNotifierProvider.notifier).reset() : null,
                  tooltip: l10n.drawingZoomReset,
                  icon: const AppIcon(AppIcons.fitScreen),
                ),
                const SizedBox(width: 8),
                AppGradientButton(
                  onTap: isDrawingEmpty ? null : () => Navigator.of(context).pop(DrawingEditorMenuAction.done),
                  child: Text(l10n.drawingDone),
                ),
              ],
            ),
            const DrawingToolbar(),
            DrawingPalette(args: args),
          ],
        ),
      ),
    );
  }
}
