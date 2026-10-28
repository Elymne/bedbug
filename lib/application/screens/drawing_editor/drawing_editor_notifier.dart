import 'package:bedbug/features/content/domain/object_values/drawing.dart';
import 'package:bedbug/features/content/domain/object_values/drawing_operation.dart';
import 'package:bedbug/features/content/domain/services/drawing_validation_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nombre maximal d'étapes gardées pour annuler.
const int _maxHistory = 100;

/// Provider du [DrawingEditorNotifier], un par ouverture de l'éditeur.
final drawingEditorNotifierProvider = NotifierProvider.autoDispose
    .family<DrawingEditorNotifier, DrawingEditorState, DrawingEditorArgs>(DrawingEditorNotifier.new);

/// Notifier portant le dessin en cours d'édition, et son historique pour annuler et rétablir.
///
/// Chaque modification passe par `DrawingValidationService` : un trait qui
/// ferait dépasser une limite (points, traits, remplissages) est refusé
/// tout de suite, pour que le dessin publié soit toujours accepté par les
/// autres téléphones.
class DrawingEditorNotifier extends Notifier<DrawingEditorState> {
  /// Crée un [DrawingEditorNotifier].
  ///
  /// - [args] : ouverture de l'éditeur, avec le dessin de départ.
  DrawingEditorNotifier(this.args);

  /// Ouverture de l'éditeur, avec le dessin de départ.
  final DrawingEditorArgs args;

  /// Service de vérification des limites d'un dessin.
  late final _drawingValidationService = ref.read(drawingValidationServiceProvider);

  @override
  DrawingEditorState build() {
    return DrawingEditorState(drawing: args.initialDrawing);
  }

  /// Ajoute [operation] au dessin, et retourne `false` si elle ferait dépasser une limite.
  ///
  /// - [operation] : trait ou remplissage à ajouter.
  bool addOperation(DrawingOperation operation) {
    final drawing = state.drawing.copyWith(operations: [...state.drawing.operations, operation]);
    if (!_drawingValidationService.isValid(drawing)) {
      return false;
    }
    _apply(drawing);
    return true;
  }

  /// Remplace la couleur en position [index] de la palette par [color], ce qui recolore tout ce qui l'utilise.
  ///
  /// - [index] : position de la couleur dans la palette.
  /// - [color] : nouvelle couleur ARGB, rendue opaque.
  void setPaletteColor(int index, int color) {
    final palette = [...state.drawing.palette];
    palette[index] = color | 0xFF000000;
    _apply(state.drawing.copyWith(palette: palette));
  }

  /// Change la taille de la surface, tant que rien n'a été dessiné. S'annule comme le reste.
  ///
  /// Un dessin commencé garde sa surface : ses points, placés dans l'ancien
  /// repère, sortiraient du nouveau ou s'y retrouveraient décalés.
  ///
  /// - [size] : nouvelle taille.
  void setSize(DrawingSize size) {
    if (state.drawing.operations.isNotEmpty || state.drawing.size == size) {
      return;
    }
    _apply(state.drawing.copyWith(size: size));
  }

  /// Change l'orientation de la surface, tant que rien n'a été dessiné. S'annule comme le reste.
  ///
  /// Même raison que pour [setSize] : un dessin commencé garde son repère.
  ///
  /// - [orientation] : nouvelle orientation.
  void setOrientation(DrawingOrientation orientation) {
    if (state.drawing.operations.isNotEmpty || state.drawing.orientation == orientation) {
      return;
    }
    _apply(state.drawing.copyWith(orientation: orientation));
  }

  /// Efface tout le dessin, en gardant sa palette. S'annule comme le reste.
  void clear() {
    if (state.drawing.operations.isEmpty) {
      return;
    }
    _apply(state.drawing.copyWith(operations: const []));
  }

  /// Revient à l'état précédant la dernière modification.
  void undo() {
    if (state.past.isEmpty) {
      return;
    }
    state = DrawingEditorState(
      drawing: state.past.last,
      past: state.past.sublist(0, state.past.length - 1),
      future: [state.drawing, ...state.future],
      revision: state.revision + 1,
    );
  }

  /// Réapplique la dernière modification annulée.
  void redo() {
    if (state.future.isEmpty) {
      return;
    }
    state = DrawingEditorState(
      drawing: state.future.first,
      past: [...state.past, state.drawing],
      future: state.future.sublist(1),
      revision: state.revision + 1,
    );
  }

  /// Remplace le dessin par [drawing], en gardant l'actuel dans l'historique.
  ///
  /// - [drawing] : nouveau dessin.
  void _apply(Drawing drawing) {
    final past = [...state.past, state.drawing];
    state = DrawingEditorState(
      drawing: drawing,
      past: past.length > _maxHistory ? past.sublist(past.length - _maxHistory) : past,
      revision: state.revision + 1,
    );
  }
}

/// État de l'éditeur de dessin.
class DrawingEditorState {
  /// Crée un [DrawingEditorState].
  ///
  /// - [drawing] : dessin actuel.
  /// - [past] : états précédents, du plus ancien au plus récent.
  /// - [future] : états annulés, du plus proche au plus lointain.
  /// - [revision] : numéro incrémenté à chaque changement du dessin.
  const DrawingEditorState({required this.drawing, this.past = const [], this.future = const [], this.revision = 0});

  /// Dessin actuel.
  final Drawing drawing;

  /// États précédents, du plus ancien au plus récent.
  final List<Drawing> past;

  /// États annulés, du plus proche au plus lointain.
  final List<Drawing> future;

  /// Numéro incrémenté à chaque changement du dessin.
  ///
  /// Permet de savoir si l'image affichée inclut déjà le dernier trait, sans
  /// comparer les dessins entre eux.
  final int revision;
}

/// Ouverture de l'éditeur de dessin : chaque ouverture a son propre état.
///
/// Identifiée par sa seule instance, sans comparer les dessins : deux
/// ouvertures sur le même dessin ne partagent pas leur historique.
class DrawingEditorArgs {
  /// Crée des [DrawingEditorArgs].
  ///
  /// - [initialDrawing] : dessin de départ.
  DrawingEditorArgs(this.initialDrawing);

  /// Dessin de départ.
  final Drawing initialDrawing;
}
