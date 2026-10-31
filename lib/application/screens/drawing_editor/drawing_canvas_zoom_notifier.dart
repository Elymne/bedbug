import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Zoom minimal de la surface de dessin : un quart de sa taille ajustée à l'écran.
const double _minZoom = 0.25;

/// Zoom maximal de la surface de dessin.
const double _maxZoom = 6;

/// Provider du [DrawingCanvasZoomNotifier].
final drawingCanvasZoomNotifierProvider = NotifierProvider.autoDispose<DrawingCanvasZoomNotifier, DrawingCanvasZoom>(
  DrawingCanvasZoomNotifier.new,
);

/// Notifier portant le zoom de la surface de dessin, et le mode zoom qui le pilote.
///
/// L'écran entier sert de fenêtre, et la surface y est posée à sa taille
/// zoomée, comme dans un logiciel de dessin : dézoomée, elle rétrécit au
/// milieu de l'écran, ce qui montre d'un coup d'œil où en est le zoom ;
/// zoomée, elle déborde et remplit tout l'écran. Les doigts ne peuvent pas à
/// la fois dessiner et déplacer : un bouton fait passer en mode zoom, où un
/// doigt déplace et deux doigts zooment, puis revient au dessin en gardant
/// le zoom. Séparé du dessin : il change au rythme des doigts, et ne
/// reconstruit que la surface.
class DrawingCanvasZoomNotifier extends Notifier<DrawingCanvasZoom> {
  /// Zoom au début du geste en cours, `null` hors d'un geste en mode zoom.
  DrawingCanvasZoom? _gestureStart;

  /// Point sous les doigts au début du geste en cours, dans le repère de l'écran.
  Offset _gestureFocalPoint = Offset.zero;

  @override
  DrawingCanvasZoom build() {
    return const DrawingCanvasZoom();
  }

  /// Entre en mode zoom, ou en sort pour revenir au dessin.
  void toggleZoomMode() {
    _gestureStart = null;
    state = state.copyWith(isZoomMode: !state.isZoomMode);
  }

  /// Commence un geste au point [focalPoint], suivi seulement en mode zoom.
  ///
  /// - [focalPoint] : point sous les doigts, dans le repère de l'écran.
  void startGesture(Offset focalPoint) {
    if (!state.isZoomMode) {
      _gestureStart = null;
      return;
    }
    _gestureStart = state;
    _gestureFocalPoint = focalPoint;
  }

  /// Applique le geste en cours : le point du dessin pris sous les doigts au départ reste sous eux.
  ///
  /// La position obtenue est aussitôt ramenée dans les limites (voir
  /// [DrawingCanvasZoom.originIn]) : la surface ne peut pas être perdue hors
  /// de l'écran.
  ///
  /// - [focalPoint] : point sous les doigts, dans le repère de l'écran.
  /// - [scale] : facteur de zoom depuis le début du geste (1 pour un simple déplacement).
  /// - [viewport] : taille de l'écran qui montre la surface.
  /// - [fitSize] : taille de la surface ajustée à l'écran, celle du zoom 1.
  void updateGesture(Offset focalPoint, double scale, Size viewport, Size fitSize) {
    final start = _gestureStart;
    if (start == null) {
      return;
    }
    final zoom = (start.scale * scale).clamp(_minZoom, _maxZoom);
    final anchor = (_gestureFocalPoint - start.originIn(viewport, fitSize)) / start.scale;
    final requested = DrawingCanvasZoom(scale: zoom, origin: focalPoint - anchor * zoom);
    state = state.copyWith(scale: zoom, origin: requested.originIn(viewport, fitSize));
  }

  /// Revient au zoom 1 : la surface entière, ajustée à l'écran, sans quitter le mode en cours.
  void reset() {
    _gestureStart = null;
    state = state.copyWith(scale: 1, origin: Offset.zero);
  }
}

/// Zoom de la surface de dessin.
class DrawingCanvasZoom {
  /// Crée un [DrawingCanvasZoom].
  ///
  /// - [scale] : facteur de zoom, 1 pour la surface ajustée à l'écran.
  /// - [origin] : position demandée du coin haut gauche de la surface, dans le repère de l'écran.
  /// - [isZoomMode] : `true` quand les doigts zooment et déplacent au lieu de dessiner.
  const DrawingCanvasZoom({this.scale = 1, this.origin = Offset.zero, this.isZoomMode = false});

  /// Facteur de zoom, 1 pour la surface ajustée à l'écran.
  final double scale;

  /// Position demandée du coin haut gauche de la surface, dans le repère de l'écran.
  ///
  /// Demandée seulement : la position affichée est celle de [originIn],
  /// qui la ramène dans les limites de l'écran.
  final Offset origin;

  /// Indique si les doigts zooment et déplacent au lieu de dessiner.
  final bool isZoomMode;

  /// Retourne la position affichée du coin haut gauche de la surface, dans le repère de l'écran.
  ///
  /// Sur chaque axe, une surface plus petite que l'écran est centrée ; une
  /// surface plus grande le couvre toujours entièrement, sans laisser de
  /// vide sur un bord.
  ///
  /// - [viewport] : taille de l'écran qui montre la surface.
  /// - [fitSize] : taille de la surface ajustée à l'écran, celle du zoom 1.
  Offset originIn(Size viewport, Size fitSize) {
    return Offset(
      _axisOrigin(origin.dx, fitSize.width * scale, viewport.width),
      _axisOrigin(origin.dy, fitSize.height * scale, viewport.height),
    );
  }

  /// Retourne une copie de ce zoom avec les champs fournis modifiés.
  ///
  /// - [scale] : nouveau facteur de zoom.
  /// - [origin] : nouvelle position demandée.
  /// - [isZoomMode] : nouveau mode.
  DrawingCanvasZoom copyWith({double? scale, Offset? origin, bool? isZoomMode}) {
    return DrawingCanvasZoom(
      scale: scale ?? this.scale,
      origin: origin ?? this.origin,
      isZoomMode: isZoomMode ?? this.isZoomMode,
    );
  }
}

/// Retourne la position affichée de la surface sur un axe.
///
/// - [requested] : position demandée.
/// - [length] : longueur de la surface zoomée sur cet axe.
/// - [viewportLength] : longueur de l'écran sur cet axe.
double _axisOrigin(double requested, double length, double viewportLength) {
  if (length <= viewportLength) {
    return (viewportLength - length) / 2;
  }
  return requested.clamp(viewportLength - length, 0);
}
