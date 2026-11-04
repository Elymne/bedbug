import 'package:bedbug/application/screens/drawing_editor/drawing_canvas_image/drawing_canvas_image.notifier.dart';
import 'package:bedbug/application/screens/drawing_editor/notifiers/drawing_editor.notifier.dart';
import 'package:bedbug/resources/content/drawing/drawing.config.dart';
import 'package:bedbug/resources/content/drawing/drawing.value_object.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [DrawingLiveStrokeNotifier], un par ouverture de l'éditeur.
final drawingLiveStrokeNotifierProvider = NotifierProvider.autoDispose
    .family<DrawingLiveStrokeNotifier, DrawingLiveStrokeState?, DrawingEditorArgs>(DrawingLiveStrokeNotifier.new);

/// Notifier portant le trait en cours de tracé, avant qu'il rejoigne le dessin.
///
/// Mis à jour à chaque mouvement du doigt : séparé du dessin, il ne reconstruit que la couche qui montre le trait en
/// cours. Le trait garde une copie de l'outil et de la palette du moment où il a commencé, qui ne peuvent pas changer
/// pendant le tracé : la couche n'a besoin de rien d'autre pour le dessiner. Une fois ajouté au dessin, le trait reste
/// affiché jusqu'à ce que l'image du dessin le contienne ([DrawingLiveStrokeState.committedRevision]), pour ne pas
/// clignoter entre les deux : le notifier suit lui-même l'image pour l'effacer à ce moment.
class DrawingLiveStrokeNotifier extends Notifier<DrawingLiveStrokeState?> {
  /// Crée un [DrawingLiveStrokeNotifier].
  ///
  /// - [args] : ouverture de l'éditeur dont le trait est tracé.
  DrawingLiveStrokeNotifier(this.args);

  /// Ouverture de l'éditeur dont le trait est tracé.
  final DrawingEditorArgs args;

  @override
  DrawingLiveStrokeState? build() {
    ref.listen(drawingCanvasImageNotifierProvider(args), (previous, next) {
      final imageRevision = next.value?.revision;
      if (imageRevision != null) {
        _clearIfShown(imageRevision);
      }
    });
    return null;
  }

  /// Commence un trait au point [point], tracé par le doigt [pointer] avec l'outil [tool].
  ///
  /// - [pointer] : identifiant du doigt qui trace.
  /// - [point] : premier point du trait.
  /// - [seed] : graine du trait, gardée jusqu'à son ajout pour que l'aperçu soit identique au résultat.
  /// - [tool] : outil choisi au début du trait (jamais le pot de peinture, qui ne trace pas de trait).
  /// - [palette] : palette du dessin au début du trait.
  void start(int pointer, DrawingPoint point, int seed, DrawingToolState tool, List<int> palette) {
    state = DrawingLiveStrokeState(
      pointer: pointer,
      tool: tool,
      palette: palette,
      stroke: _buildStroke(tool, [point], seed),
    );
  }

  /// Prolonge le trait du doigt [pointer] jusqu'à [point].
  ///
  /// Un autre doigt, un point identique au précédent, ou un trait déjà
  /// plein ([maxDrawingStrokePoints]) sont ignorés.
  ///
  /// - [pointer] : identifiant du doigt qui trace.
  /// - [point] : nouveau point.
  void extend(int pointer, DrawingPoint point) {
    final current = state;
    if (current == null || current.pointer != pointer || current.committedRevision != null) {
      return;
    }
    final points = current.stroke.points;
    if (points.last == point || points.length >= maxDrawingStrokePoints) {
      return;
    }
    state = current.copyWith(stroke: _buildStroke(current.tool, [...points, point], current.stroke.seed));
  }

  /// Retourne le trait du doigt [pointer], simplifié et prêt à rejoindre le dessin.
  ///
  /// Retourne `null` si ce doigt ne trace aucun trait en cours.
  ///
  /// - [pointer] : identifiant du doigt levé.
  DrawingStroke? strokeToCommit(int pointer) {
    final current = state;
    if (current == null || current.pointer != pointer || current.committedRevision != null) {
      return null;
    }
    return _buildStroke(current.tool, Drawing.simplifyStroke(current.stroke.points), current.stroke.seed);
  }

  /// Marque le trait comme ajouté au dessin, à la révision [revision].
  ///
  /// - [revision] : révision du dessin qui contient le trait.
  void commit(int revision) {
    final current = state;
    if (current == null) {
      return;
    }
    state = current.copyWith(committedRevision: revision);
    final imageRevision = ref.read(drawingCanvasImageNotifierProvider(args)).value?.revision;
    if (imageRevision != null) {
      _clearIfShown(imageRevision);
    }
  }

  /// Abandonne le trait en cours.
  void cancel() {
    state = null;
  }

  /// Efface le trait déjà ajouté au dessin dès que l'image, à la révision [imageRevision], le contient.
  ///
  /// - [imageRevision] : révision du dessin montrée par l'image.
  void _clearIfShown(int imageRevision) {
    final committedRevision = state?.committedRevision;
    if (committedRevision != null && imageRevision >= committedRevision) {
      state = null;
    }
  }

  /// Retourne le trait passant par [points] avec l'outil [tool].
  ///
  /// - [tool] : outil du trait.
  /// - [points] : points du trait.
  /// - [seed] : graine du trait.
  DrawingStroke _buildStroke(DrawingToolState tool, List<DrawingPoint> points, int seed) {
    return DrawingStroke(
      layer: tool.layer,
      colorIndex: tool.colorIndex,
      brush: switch (tool.tool) {
        DrawingTool.pen || DrawingTool.fill => DrawingBrush.pen,
        DrawingTool.marker => DrawingBrush.marker,
        DrawingTool.pencil => DrawingBrush.pencil,
        DrawingTool.spray => DrawingBrush.spray,
        DrawingTool.eraser => DrawingBrush.eraser,
      },
      size: tool.sizeIndex,
      seed: seed,
      points: points,
    );
  }
}

/// Trait en cours de tracé.
class DrawingLiveStrokeState {
  /// Crée un [DrawingLiveStrokeState].
  ///
  /// - [pointer] : identifiant du doigt qui trace.
  /// - [tool] : outil choisi au début du trait.
  /// - [palette] : palette du dessin au début du trait.
  /// - [stroke] : trait tracé jusqu'ici, points bruts compris.
  /// - [committedRevision] : révision du dessin qui contient le trait, `null` tant qu'il est en cours.
  const DrawingLiveStrokeState({
    required this.pointer,
    required this.tool,
    required this.palette,
    required this.stroke,
    this.committedRevision,
  });

  /// Identifiant du doigt qui trace.
  final int pointer;

  /// Outil choisi au début du trait.
  final DrawingToolState tool;

  /// Palette du dessin au début du trait.
  final List<int> palette;

  /// Trait tracé jusqu'ici, points bruts compris.
  final DrawingStroke stroke;

  /// Révision du dessin qui contient le trait, `null` tant qu'il est en cours.
  final int? committedRevision;

  /// Retourne une copie de ce trait avec les champs fournis modifiés.
  ///
  /// - [stroke] : nouveau trait.
  /// - [committedRevision] : révision du dessin qui contient le trait.
  DrawingLiveStrokeState copyWith({DrawingStroke? stroke, int? committedRevision}) {
    return DrawingLiveStrokeState(
      pointer: pointer,
      tool: tool,
      palette: palette,
      stroke: stroke ?? this.stroke,
      committedRevision: committedRevision ?? this.committedRevision,
    );
  }
}
