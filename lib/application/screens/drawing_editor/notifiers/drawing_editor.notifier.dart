import 'package:bedbug/application/notifiers/drawing_draft.notifier.dart';
import 'package:bedbug/resources/content/drawing/drawing.value_object.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nombre maximal d'étapes gardées pour annuler.
const int _maxHistory = 100;

/// Provider du [DrawingEditorNotifier], un par ouverture de l'éditeur.
final drawingEditorNotifierProvider = NotifierProvider.autoDispose
    .family<DrawingEditorNotifier, DrawingEditorState, DrawingEditorArgs>(DrawingEditorNotifier.new);

/// Notifier portant le dessin en cours d'édition, son historique pour annuler et rétablir, et l'outil choisi.
///
/// Chaque modification du dessin passe par `Drawing.isValid` : un trait qui
/// ferait dépasser une limite (points, traits, remplissages) est refusé
/// tout de suite, pour que le dessin publié soit toujours accepté par les
/// autres téléphones.
///
/// L'outil vit ici plutôt que dans un notifier à part : la palette et le bouton du menu affichent la couleur choisie
/// dans la palette du dessin, et ne doivent observer qu'un notifier. Il reste hors de l'historique : changer d'outil
/// ne modifie pas le dessin, ne s'annule pas et n'est pas enregistré dans le brouillon.
class DrawingEditorNotifier extends Notifier<DrawingEditorState> {
  /// Crée un [DrawingEditorNotifier].
  ///
  /// - [args] : ouverture de l'éditeur, avec le dessin de départ.
  DrawingEditorNotifier(this.args);

  /// Ouverture de l'éditeur, avec le dessin de départ.
  final DrawingEditorArgs args;

  /// Brouillon du dessin en cours, mis à jour à chaque modification.
  late final _drawingDraftNotifier = ref.read(drawingDraftNotifierProvider.notifier);

  @override
  DrawingEditorState build() {
    return DrawingEditorState(
      drawing: args.initialDrawing,
      // Stylo moyen, noir, sur le calque du milieu : le fond reste libre pour les remplissages.
      tool: const DrawingToolState(tool: DrawingTool.pen, sizeIndex: 1, colorIndex: 0, layer: 1),
    );
  }

  /// Ajoute [operation] au dessin, et retourne `false` si elle ferait dépasser une limite.
  ///
  /// - [operation] : trait ou remplissage à ajouter.
  bool addOperation(DrawingOperation operation) {
    final drawing = state.drawing.copyWith(operations: [...state.drawing.operations, operation]);
    if (!Drawing.isValid(drawing)) {
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
    _update(
      state.copyWith(
        drawing: state.past.last,
        past: state.past.sublist(0, state.past.length - 1),
        future: [state.drawing, ...state.future],
        revision: state.revision + 1,
      ),
    );
  }

  /// Réapplique la dernière modification annulée.
  void redo() {
    if (state.future.isEmpty) {
      return;
    }
    _update(
      state.copyWith(
        drawing: state.future.first,
        past: [...state.past, state.drawing],
        future: state.future.sublist(1),
        revision: state.revision + 1,
      ),
    );
  }

  /// Choisit l'outil [tool].
  ///
  /// - [tool] : outil choisi.
  void setTool(DrawingTool tool) {
    state = state.copyWith(tool: state.tool.copyWith(tool: tool));
  }

  /// Choisit la taille de pinceau en position [sizeIndex].
  ///
  /// - [sizeIndex] : position de la taille, de la plus fine à la plus épaisse.
  void setSize(int sizeIndex) {
    state = state.copyWith(tool: state.tool.copyWith(sizeIndex: sizeIndex));
  }

  /// Choisit la couleur en position [colorIndex] de la palette.
  ///
  /// - [colorIndex] : position de la couleur dans la palette.
  void setColor(int colorIndex) {
    state = state.copyWith(tool: state.tool.copyWith(colorIndex: colorIndex));
  }

  /// Choisit le calque [layer], sur lequel s'appliquent les prochains traits et remplissages.
  ///
  /// - [layer] : calque, de 0 (fond) au calque du dessus.
  void setLayer(int layer) {
    state = state.copyWith(tool: state.tool.copyWith(layer: layer));
  }

  /// Remplace le dessin par [drawing], en gardant l'actuel dans l'historique.
  ///
  /// Les modifications annulées sont oubliées : on ne rétablit plus après avoir modifié le dessin.
  ///
  /// - [drawing] : nouveau dessin.
  void _apply(Drawing drawing) {
    final past = [...state.past, state.drawing];
    _update(
      state.copyWith(
        drawing: drawing,
        past: past.length > _maxHistory ? past.sublist(past.length - _maxHistory) : past,
        future: const [],
        revision: state.revision + 1,
      ),
    );
  }

  /// Passe à l'état [next], et enregistre son dessin comme brouillon.
  ///
  /// Chaque changement est enregistré aussitôt, sans attendre : si le
  /// système ferme l'app pendant que l'utilisateur est ailleurs, il retrouve
  /// son dessin au dernier trait près.
  ///
  /// - [next] : nouvel état de l'éditeur.
  void _update(DrawingEditorState next) {
    state = next;
    _drawingDraftNotifier.save(next.drawing);
  }
}

/// État de l'éditeur de dessin.
class DrawingEditorState {
  /// Crée un [DrawingEditorState].
  ///
  /// - [drawing] : dessin actuel.
  /// - [tool] : outil choisi.
  /// - [past] : états précédents, du plus ancien au plus récent.
  /// - [future] : états annulés, du plus proche au plus lointain.
  /// - [revision] : numéro incrémenté à chaque changement du dessin.
  const DrawingEditorState({
    required this.drawing,
    required this.tool,
    this.past = const [],
    this.future = const [],
    this.revision = 0,
  });

  /// Dessin actuel.
  final Drawing drawing;

  /// Outil choisi.
  final DrawingToolState tool;

  /// États précédents, du plus ancien au plus récent.
  final List<Drawing> past;

  /// États annulés, du plus proche au plus lointain.
  final List<Drawing> future;

  /// Numéro incrémenté à chaque changement du dessin, jamais à un changement d'outil.
  ///
  /// Permet de savoir si l'image affichée inclut déjà le dernier trait, sans
  /// comparer les dessins entre eux.
  final int revision;

  /// Retourne une copie de cet état avec les champs fournis modifiés.
  ///
  /// - [drawing] : nouveau dessin.
  /// - [tool] : nouvel outil.
  /// - [past] : nouveaux états précédents.
  /// - [future] : nouveaux états annulés.
  /// - [revision] : nouvelle révision.
  DrawingEditorState copyWith({
    Drawing? drawing,
    DrawingToolState? tool,
    List<Drawing>? past,
    List<Drawing>? future,
    int? revision,
  }) {
    return DrawingEditorState(
      drawing: drawing ?? this.drawing,
      tool: tool ?? this.tool,
      past: past ?? this.past,
      future: future ?? this.future,
      revision: revision ?? this.revision,
    );
  }
}

/// Outil choisi dans l'éditeur de dessin : pinceau, taille, couleur et calque.
class DrawingToolState {
  /// Crée un [DrawingToolState].
  ///
  /// - [tool] : outil choisi.
  /// - [sizeIndex] : position de la taille de pinceau.
  /// - [colorIndex] : position de la couleur dans la palette.
  /// - [layer] : calque des prochaines opérations.
  const DrawingToolState({required this.tool, required this.sizeIndex, required this.colorIndex, required this.layer});

  /// Outil choisi.
  final DrawingTool tool;

  /// Position de la taille de pinceau.
  final int sizeIndex;

  /// Position de la couleur dans la palette.
  final int colorIndex;

  /// Calque des prochaines opérations.
  final int layer;

  /// Retourne une copie de cet état avec les champs fournis modifiés.
  DrawingToolState copyWith({DrawingTool? tool, int? sizeIndex, int? colorIndex, int? layer}) {
    return DrawingToolState(
      tool: tool ?? this.tool,
      sizeIndex: sizeIndex ?? this.sizeIndex,
      colorIndex: colorIndex ?? this.colorIndex,
      layer: layer ?? this.layer,
    );
  }
}

/// Outil de l'éditeur de dessin : un pinceau, ou le pot de peinture.
enum DrawingTool {
  /// Stylo.
  pen,

  /// Feutre.
  marker,

  /// Crayon.
  pencil,

  /// Bombe.
  spray,

  /// Gomme.
  eraser,

  /// Pot de peinture.
  fill,
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
