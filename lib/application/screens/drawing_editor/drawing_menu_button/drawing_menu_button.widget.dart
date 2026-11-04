import 'package:bedbug/application/notifiers/drawing_draft.notifier.dart';
import 'package:bedbug/application/screens/drawing_editor/drawing_editor.config.dart';
import 'package:bedbug/application/screens/drawing_editor/drawing_editor_menu/drawing_editor_menu.widget.dart';
import 'package:bedbug/application/screens/drawing_editor/notifiers/drawing_editor.notifier.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/widgets/icons/app_icon.widget.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Épaisseur de l'anneau du bouton, à la couleur en cours.
const double _kColorRingWidth = 3;

/// Bouton flottant qui ouvre le menu de l'éditeur, cerclé de la couleur en cours.
///
/// Ferme ou valide l'éditeur si le menu le demande. N'observe que la couleur choisie : changer d'outil ou dessiner ne
/// le reconstruit pas.
class DrawingMenuButton extends ConsumerWidget {
  /// Crée un [DrawingMenuButton].
  ///
  /// - [args] : ouverture de l'éditeur dont le menu règle les outils.
  const DrawingMenuButton({super.key, required this.args});

  /// Ouverture de l'éditeur dont le menu règle les outils.
  final DrawingEditorArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = ref.watch(
      drawingEditorNotifierProvider(args).select((state) => state.drawing.palette[state.tool.colorIndex]),
    );

    return IconButton(
      onPressed: () => _openMenu(context, ref),
      tooltip: context.loc.drawingMenu,
      style: drawingEditorButtonStyle.copyWith(
        side: WidgetStatePropertyAll(BorderSide(color: Color(color), width: _kColorRingWidth)),
      ),
      icon: const AppIcon(AppIcons.palette),
    );
  }

  /// Ouvre le menu de l'éditeur, puis ferme ou valide l'éditeur si le menu le demande.
  ///
  /// Dans les deux cas, le brouillon est effacé : le dessin est soit rendu à
  /// la page de création, soit abandonné volontairement.
  ///
  /// - [context] : contexte depuis lequel ouvrir le menu et quitter l'éditeur.
  /// - [ref] : accès au dessin et au brouillon.
  Future<void> _openMenu(BuildContext context, WidgetRef ref) async {
    final action = await showModalBottomSheet<DrawingEditorMenuAction>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DrawingEditorMenu(args: args),
    );
    if (action == null || !context.mounted) {
      return;
    }
    final drawing = ref.read(drawingEditorNotifierProvider(args)).drawing;
    await ref.read(drawingDraftNotifierProvider.notifier).clear();
    if (!context.mounted) {
      return;
    }
    if (action == DrawingEditorMenuAction.close) {
      context.pop();
      return;
    }
    context.pop(drawing);
  }
}
