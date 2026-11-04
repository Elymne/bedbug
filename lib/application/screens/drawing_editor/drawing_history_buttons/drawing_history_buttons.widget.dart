import 'package:bedbug/application/screens/drawing_editor/notifiers/drawing_editor.notifier.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/widgets/icons/app_icon.widget.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Boutons du menu qui agissent sur l'historique du dessin : rétablir, et tout effacer.
///
/// Chacun est grisé tant qu'il n'a rien à faire : rien d'annulé à rétablir, ou un dessin déjà vide.
class DrawingHistoryButtons extends ConsumerWidget {
  /// Crée un [DrawingHistoryButtons].
  ///
  /// - [args] : ouverture de l'éditeur dont le dessin est modifié.
  const DrawingHistoryButtons({super.key, required this.args});

  /// Ouverture de l'éditeur dont le dessin est modifié.
  final DrawingEditorArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(
      drawingEditorNotifierProvider(args)
          .select((state) => (canRedo: state.future.isNotEmpty, isEmpty: state.drawing.operations.isEmpty)),
    );
    final l10n = context.loc;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: history.canRedo ? () => ref.read(drawingEditorNotifierProvider(args).notifier).redo() : null,
          tooltip: l10n.drawingRedo,
          icon: const AppIcon(AppIcons.redo),
        ),
        IconButton(
          onPressed: history.isEmpty ? null : () => ref.read(drawingEditorNotifierProvider(args).notifier).clear(),
          tooltip: l10n.drawingClear,
          icon: const AppIcon(AppIcons.deleteAll),
        ),
      ],
    );
  }
}
