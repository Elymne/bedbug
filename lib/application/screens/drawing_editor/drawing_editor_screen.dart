import 'package:bedbug/application/notifiers/drawing_draft_notifier.dart';
import 'package:bedbug/application/screens/drawing_editor/drawing_canvas_zoom_notifier.dart';
import 'package:bedbug/application/screens/drawing_editor/drawing_editor_notifier.dart';
import 'package:bedbug/application/screens/drawing_editor/drawing_tool_notifier.dart';
import 'package:bedbug/application/screens/drawing_editor/widgets/drawing_canvas.dart';
import 'package:bedbug/application/screens/drawing_editor/widgets/drawing_editor_menu.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/widgets/icons/app_icon.dart';
import 'package:bedbug/features/content/domain/object_values/drawing.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Marge entre les boutons flottants et le bord de l'écran.
const double _kButtonMargin = 8;

/// Épaisseur de l'anneau du bouton du menu, à la couleur en cours.
const double _kColorRingWidth = 3;

/// Éditeur de dessin, la surface sur tout l'écran.
///
/// Seuls trois boutons flottent par-dessus le dessin : le menu (outils,
/// gomme, couleurs, calques, valider…), le mode zoom, et annuler, le geste
/// le plus fréquent. Le dessin en cours est enregistré comme brouillon à
/// chaque trait ; le brouillon est effacé quand l'éditeur est validé ou
/// fermé depuis le menu. Retourne le dessin validé à la page qui l'a ouvert
/// (`context.pop`), ou rien si l'utilisateur ferme l'éditeur.
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
    final l10n = context.loc;
    final canUndo = ref.watch(drawingEditorNotifierProvider(_args).select((state) => state.past.isNotEmpty));
    final palette = ref.watch(drawingEditorNotifierProvider(_args).select((state) => state.drawing.palette));
    // Écouté ici aussi pour que l'outil choisi survive à la fermeture du menu, qui était seul à le lire.
    final colorIndex = ref.watch(drawingToolNotifierProvider.select((state) => state.colorIndex));
    final buttonStyle = IconButton.styleFrom(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.onLight,
      side: const BorderSide(color: AppColors.border),
    );

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
                    IconButton(
                      onPressed: _openMenu,
                      tooltip: l10n.drawingMenu,
                      style: buttonStyle.copyWith(
                        side: WidgetStatePropertyAll(
                          BorderSide(color: Color(palette[colorIndex]), width: _kColorRingWidth),
                        ),
                      ),
                      icon: const AppIcon(AppIcons.palette),
                    ),
                    // Le zoom change au rythme des doigts : seul son bouton se reconstruit.
                    Consumer(
                      builder: (context, ref, _) {
                        final isZoomMode = ref.watch(
                          drawingCanvasZoomNotifierProvider.select((zoom) => zoom.isZoomMode),
                        );
                        return IconButton(
                          onPressed: () => ref.read(drawingCanvasZoomNotifierProvider.notifier).toggleZoomMode(),
                          tooltip: l10n.drawingZoomMode,
                          isSelected: isZoomMode,
                          style: buttonStyle.copyWith(
                            backgroundColor: WidgetStatePropertyAll(isZoomMode ? AppColors.primary : AppColors.surface),
                            foregroundColor: WidgetStatePropertyAll(isZoomMode ? AppColors.onDark : AppColors.onLight),
                          ),
                          icon: const AppIcon(AppIcons.zoomIn),
                        );
                      },
                    ),
                    IconButton(
                      onPressed: canUndo ? () => ref.read(drawingEditorNotifierProvider(_args).notifier).undo() : null,
                      tooltip: l10n.drawingUndo,
                      style: buttonStyle,
                      icon: const AppIcon(AppIcons.undo),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Ouvre le menu de l'éditeur, puis ferme ou valide l'éditeur si le menu le demande.
  ///
  /// Dans les deux cas, le brouillon est effacé : le dessin est soit rendu à
  /// la page de création, soit abandonné volontairement.
  Future<void> _openMenu() async {
    final action = await showModalBottomSheet<DrawingEditorMenuAction>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DrawingEditorMenu(args: _args),
    );
    if (action == null || !mounted) {
      return;
    }
    final drawing = ref.read(drawingEditorNotifierProvider(_args)).drawing;
    await ref.read(drawingDraftNotifierProvider.notifier).clear();
    if (!mounted) {
      return;
    }
    if (action == DrawingEditorMenuAction.close) {
      context.pop();
      return;
    }
    context.pop(drawing);
  }
}
