import 'package:bedbug/application/screens/drawing_editor/drawing_canvas/drawing_canvas.widget.dart';
import 'package:bedbug/application/screens/drawing_editor/drawing_menu_button/drawing_menu_button.widget.dart';
import 'package:bedbug/application/screens/drawing_editor/drawing_undo_button/drawing_undo_button.widget.dart';
import 'package:bedbug/application/screens/drawing_editor/drawing_zoom_mode_button/drawing_zoom_mode_button.widget.dart';
import 'package:bedbug/application/screens/drawing_editor/notifiers/drawing_editor.notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/resources/content/drawing/drawing.value_object.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Marge entre les boutons flottants et le bord de l'écran.
const double _kButtonMargin = 8;

/// Éditeur de dessin, la surface sur tout l'écran.
///
/// Seuls trois boutons flottent par-dessus le dessin : le menu (outils,
/// gomme, couleurs, calques, valider…), le mode zoom, et annuler, le geste
/// le plus fréquent. Le dessin en cours est enregistré comme brouillon à
/// chaque trait ; le brouillon est effacé quand l'éditeur est validé ou
/// fermé depuis le menu. Retourne le dessin validé à la page qui l'a ouvert
/// (`context.pop`), ou rien si l'utilisateur ferme l'éditeur.
///
/// Page statique : elle ne garde que l'ouverture de l'éditeur ([DrawingEditorArgs]), à laquelle tous ses widgets
/// rattachent leur état.
class DrawingEditorScreen extends ConsumerStatefulWidget {
  /// Crée un [DrawingEditorScreen].
  ///
  /// - [initialDrawing] : dessin à reprendre, ou dessin vide à la surface choisie.
  const DrawingEditorScreen({super.key, required this.initialDrawing});

  /// Dessin à reprendre, ou dessin vide à la surface choisie.
  final Drawing initialDrawing;

  @override
  ConsumerState<DrawingEditorScreen> createState() => _State();
}

class _State extends ConsumerState<DrawingEditorScreen> {
  /// Ouverture de l'éditeur : l'historique et l'image du dessin lui sont propres.
  late final DrawingEditorArgs _args = DrawingEditorArgs(widget.initialDrawing);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Un fond gris, comme dans un logiciel de dessin : la surface blanche s'en détache quand on dézoome.
      backgroundColor: AppColors.border,
      body: Stack(
        children: [
          Positioned.fill(child: DrawingCanvas(args: _args)),
          SafeArea(
            child: Align(
              alignment: AlignmentDirectional.topEnd,
              child: Padding(
                padding: const EdgeInsets.all(_kButtonMargin),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    DrawingMenuButton(args: _args),
                    const DrawingZoomModeButton(),
                    DrawingUndoButton(args: _args),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
