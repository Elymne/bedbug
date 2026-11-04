import 'package:bedbug/application/screens/drawing_editor/drawing_done_button/drawing_done_button.widget.dart';
import 'package:bedbug/application/screens/drawing_editor/drawing_history_buttons/drawing_history_buttons.widget.dart';
import 'package:bedbug/application/screens/drawing_editor/drawing_palette/drawing_palette.widget.dart';
import 'package:bedbug/application/screens/drawing_editor/drawing_toolbar/drawing_toolbar.widget.dart';
import 'package:bedbug/application/screens/drawing_editor/drawing_zoom_reset_button/drawing_zoom_reset_button.widget.dart';
import 'package:bedbug/application/screens/drawing_editor/notifiers/drawing_editor.notifier.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/widgets/icons/app_icon.widget.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
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
/// ([DrawingEditorMenuAction]), que l'éditeur exécute. Statique : chaque partie du menu observe elle-même ce qu'elle
/// affiche.
class DrawingEditorMenu extends ConsumerWidget {
  /// Crée un [DrawingEditorMenu].
  ///
  /// - [args] : ouverture de l'éditeur dont le menu règle les outils.
  const DrawingEditorMenu({super.key, required this.args});

  /// Ouverture de l'éditeur dont le menu règle les outils.
  final DrawingEditorArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  tooltip: context.loc.close,
                  icon: const AppIcon(AppIcons.close),
                ),
                const Spacer(),
                DrawingHistoryButtons(args: args),
                const DrawingZoomResetButton(),
                const SizedBox(width: 8),
                DrawingDoneButton(args: args),
              ],
            ),
            DrawingToolbar(args: args),
            DrawingPalette(args: args),
          ],
        ),
      ),
    );
  }
}
