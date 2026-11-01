import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Garde [child] visible en haut de la zone de défilement tant que son parent l'est encore.
///
/// Fonctionne à n'importe quelle profondeur d'une liste ordinaire, là où un
/// en-tête de sliver doit être un enfant direct de la zone de défilement : le
/// formulaire de signature vit par exemple dans une section dépliable des
/// paramètres. [child] glisse dans la hauteur de son parent sans en sortir.
///
/// Doit être dessiné après les widgets qu'il recouvre : dans une `Column`, le
/// placer en dernier avec `verticalDirection: VerticalDirection.up`.
class AppStickyTop extends SingleChildRenderObjectWidget {
  /// Crée un [AppStickyTop].
  ///
  /// - [child] : widget à garder visible.
  const AppStickyTop({super.key, required Widget super.child});

  @override
  RenderStickyTop createRenderObject(BuildContext context) {
    return RenderStickyTop(Scrollable.maybeOf(context)?.position);
  }

  @override
  void updateRenderObject(BuildContext context, RenderStickyTop renderObject) {
    renderObject.scrollPosition = Scrollable.maybeOf(context)?.position;
  }
}

/// Boîte de rendu décalant son enfant vers le bas pour compenser le défilement.
///
/// Le décalage est calculé au dessin et non au build : un défilement ne
/// reconstruit ainsi ni l'aperçu ni le formulaire qui l'entoure.
class RenderStickyTop extends RenderProxyBox {
  /// Crée un [RenderStickyTop].
  ///
  /// - [_scrollPosition] : position de la zone de défilement à suivre, `null` s'il n'y en a pas.
  RenderStickyTop(this._scrollPosition);

  /// Position de la zone de défilement à suivre, `null` s'il n'y en a pas.
  ScrollPosition? _scrollPosition;

  /// Remplace la position suivie, par exemple quand la zone de défilement change.
  ///
  /// - [value] : nouvelle position à suivre.
  set scrollPosition(ScrollPosition? value) {
    if (value == _scrollPosition) {
      return;
    }
    if (attached) {
      _scrollPosition?.removeListener(markNeedsPaint);
      value?.addListener(markNeedsPaint);
    }
    _scrollPosition = value;
    markNeedsPaint();
  }

  /// Décalage vertical à appliquer à l'enfant pour qu'il reste en haut de la zone de défilement.
  double get _shift {
    final parentBox = parent;
    final viewport = RenderAbstractViewport.maybeOf(this);
    if (parentBox is! RenderBox || viewport is! RenderObject) {
      return 0;
    }
    final top = MatrixUtils.transformPoint(getTransformTo(viewport as RenderObject), Offset.zero).dy;
    return (-top).clamp(0.0, math.max(0.0, parentBox.size.height - size.height));
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _scrollPosition?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _scrollPosition?.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset + Offset(0, _shift));
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.translateByDouble(0, _shift, 0, 1);
  }

  /// Teste la position à l'endroit où l'enfant est dessiné, et non à sa place d'origine.
  ///
  /// - [result] : résultat du test à compléter.
  /// - [position] : position testée, dans le repère de cette boîte.
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    return result.addWithPaintOffset(
      offset: Offset(0, _shift),
      position: position,
      hitTest: (result, transformed) => super.hitTest(result, position: transformed),
    );
  }

  /// Retient les taps, pour qu'ils n'atteignent pas un champ caché sous l'enfant.
  ///
  /// - [position] : position testée.
  @override
  bool hitTestSelf(Offset position) {
    return true;
  }
}
