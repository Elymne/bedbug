import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Zoom maximal de la surface de dessin.
const double _maxZoom = 6;

/// Provider du [DrawingCanvasZoomNotifier].
final drawingCanvasZoomNotifierProvider = NotifierProvider.autoDispose<DrawingCanvasZoomNotifier, DrawingCanvasZoom>(
  DrawingCanvasZoomNotifier.new,
);

/// Notifier portant le zoom de la surface de dessin, et le mode zoom qui le pilote.
///
/// La surface tient dans l'espace que lui laisse l'écran, quelle que soit sa
/// taille : sur un petit téléphone, sur une grande surface, ou pour un
/// détail, on zoome plutôt que de réduire le dessin. Les doigts ne peuvent
/// pas à la fois dessiner et déplacer : un bouton fait passer en mode zoom,
/// où un doigt déplace et deux doigts zooment, puis revient au dessin en
/// gardant le zoom. Séparé du dessin : il change au rythme des doigts, et ne
/// reconstruit que la surface.
class DrawingCanvasZoomNotifier extends Notifier<DrawingCanvasZoom> {
  /// Zoom au début du geste en cours, `null` hors d'un geste en mode zoom.
  DrawingCanvasZoom? _gestureStart;

  /// Point sous les doigts au début du geste en cours, dans le repère de la surface affichée.
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
  /// - [focalPoint] : point sous les doigts, dans le repère de la surface affichée.
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
  /// Le zoom ne descend pas sous 1 et le dessin couvre toujours toute la
  /// surface : on ne peut pas le perdre hors de l'écran.
  ///
  /// - [focalPoint] : point sous les doigts, dans le repère de la surface affichée.
  /// - [scale] : facteur de zoom depuis le début du geste (1 pour un simple déplacement).
  /// - [viewport] : taille de la surface affichée.
  void updateGesture(Offset focalPoint, double scale, Size viewport) {
    final start = _gestureStart;
    if (start == null) {
      return;
    }
    final zoom = (start.scale * scale).clamp(1.0, _maxZoom);
    final anchor = (_gestureFocalPoint - start.offset) / start.scale;
    final offset = focalPoint - anchor * zoom;
    state = state.copyWith(
      scale: zoom,
      offset: Offset(offset.dx.clamp(viewport.width * (1 - zoom), 0), offset.dy.clamp(viewport.height * (1 - zoom), 0)),
    );
  }

  /// Dézoome entièrement : la surface redevient visible en entier, sans quitter le mode en cours.
  void reset() {
    _gestureStart = null;
    state = state.copyWith(scale: 1, offset: Offset.zero);
  }
}

/// Zoom de la surface de dessin.
class DrawingCanvasZoom {
  /// Crée un [DrawingCanvasZoom].
  ///
  /// - [scale] : facteur de zoom, 1 pour la surface entière.
  /// - [offset] : décalage du dessin zoomé, en pixels de la surface affichée.
  /// - [isZoomMode] : `true` quand les doigts zooment et déplacent au lieu de dessiner.
  const DrawingCanvasZoom({this.scale = 1, this.offset = Offset.zero, this.isZoomMode = false});

  /// Facteur de zoom, 1 pour la surface entière.
  final double scale;

  /// Décalage du dessin zoomé, en pixels de la surface affichée.
  final Offset offset;

  /// Indique si les doigts zooment et déplacent au lieu de dessiner.
  final bool isZoomMode;

  /// Retourne une copie de ce zoom avec les champs fournis modifiés.
  ///
  /// - [scale] : nouveau facteur de zoom.
  /// - [offset] : nouveau décalage.
  /// - [isZoomMode] : nouveau mode.
  DrawingCanvasZoom copyWith({double? scale, Offset? offset, bool? isZoomMode}) {
    return DrawingCanvasZoom(
      scale: scale ?? this.scale,
      offset: offset ?? this.offset,
      isZoomMode: isZoomMode ?? this.isZoomMode,
    );
  }
}
