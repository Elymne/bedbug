import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [DrawingToolNotifier].
final drawingToolNotifierProvider = NotifierProvider.autoDispose<DrawingToolNotifier, DrawingToolState>(
  DrawingToolNotifier.new,
);

/// Notifier portant l'outil choisi dans l'éditeur de dessin : pinceau, taille, couleur et calque.
///
/// État d'interface, séparé du dessin lui-même : changer d'outil ne modifie
/// pas le dessin, et ne s'annule pas.
class DrawingToolNotifier extends Notifier<DrawingToolState> {
  @override
  DrawingToolState build() {
    // Stylo moyen, noir, sur le calque du milieu : le fond reste libre pour les remplissages.
    return const DrawingToolState(tool: DrawingTool.pen, sizeIndex: 1, colorIndex: 0, layer: 1);
  }

  /// Choisit l'outil [tool].
  ///
  /// - [tool] : outil choisi.
  void setTool(DrawingTool tool) {
    state = state.copyWith(tool: tool);
  }

  /// Choisit la taille de pinceau en position [sizeIndex].
  ///
  /// - [sizeIndex] : position de la taille, de la plus fine à la plus épaisse.
  void setSize(int sizeIndex) {
    state = state.copyWith(sizeIndex: sizeIndex);
  }

  /// Choisit la couleur en position [colorIndex] de la palette.
  ///
  /// - [colorIndex] : position de la couleur dans la palette.
  void setColor(int colorIndex) {
    state = state.copyWith(colorIndex: colorIndex);
  }

  /// Choisit le calque [layer], sur lequel s'appliquent les prochains traits et remplissages.
  ///
  /// - [layer] : calque, de 0 (fond) au calque du dessus.
  void setLayer(int layer) {
    state = state.copyWith(layer: layer);
  }
}

/// Outil choisi dans l'éditeur de dessin.
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
