import 'package:bedbug/application/widgets/scatter/scatter_placement.dart';
import 'package:flutter/rendering.dart';

/// Données de placement d'un enfant de [RenderScatter].
class ScatterParentData extends ContainerBoxParentData<RenderBox> {}

/// Boîte de rendu qui disperse ses enfants au hasard sur toute sa largeur, sans chevauchement.
///
/// Les enfants sont d'abord mesurés à leur taille naturelle (bornée par la
/// largeur disponible) : c'est la seule façon de connaître la place réelle
/// d'un message, qui dépend de sa longueur et de la police. Leurs positions
/// sont ensuite calculées par [placeScattered], et la boîte prend la hauteur
/// qu'ils occupent.
class RenderScatter extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, ScatterParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, ScatterParentData> {
  /// Crée un [RenderScatter].
  ///
  /// - [seed] : graine du tirage aléatoire des positions.
  /// - [spacing] : espace minimal laissé entre deux enfants.
  RenderScatter({required this._seed, required this._spacing});

  /// Graine du tirage aléatoire des positions.
  int _seed;

  /// Espace minimal laissé entre deux enfants.
  double _spacing;

  /// Graine du tirage aléatoire des positions. La changer relance le placement.
  int get seed {
    return _seed;
  }

  set seed(int value) {
    if (value == _seed) {
      return;
    }
    _seed = value;
    markNeedsLayout();
  }

  /// Espace minimal laissé entre deux enfants. Le changer relance le placement.
  double get spacing {
    return _spacing;
  }

  set spacing(double value) {
    if (value == _spacing) {
      return;
    }
    _spacing = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ScatterParentData) {
      child.parentData = ScatterParentData();
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final childConstraints = BoxConstraints(maxWidth: constraints.maxWidth);
    final placement = _place([for (final child in _children) child.getDryLayout(childConstraints)], constraints);
    return constraints.constrain(Size(constraints.maxWidth, placement.height));
  }

  @override
  void performLayout() {
    final childConstraints = BoxConstraints(maxWidth: constraints.maxWidth);
    final children = _children.toList();
    for (final child in children) {
      child.layout(childConstraints, parentUsesSize: true);
    }

    final placement = _place([for (final child in children) child.size], constraints);
    for (final (index, child) in children.indexed) {
      (child.parentData! as ScatterParentData).offset = placement.offsets[index];
    }
    size = constraints.constrain(Size(constraints.maxWidth, placement.height));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  /// Enfants dans l'ordre, parcourus via leurs données de placement.
  Iterable<RenderBox> get _children sync* {
    var child = firstChild;
    while (child != null) {
      yield child;
      child = childAfter(child);
    }
  }

  /// Calcule le placement d'enfants de tailles [sizes] pour les contraintes [constraints].
  ///
  /// La largeur doit être bornée : sans largeur, il n'y a pas de surface sur
  /// laquelle disperser les enfants.
  ScatterPlacement _place(List<Size> sizes, BoxConstraints constraints) {
    assert(constraints.hasBoundedWidth, 'RenderScatter a besoin d\'une largeur bornée pour disperser ses enfants.');
    return placeScattered(sizes: sizes, width: constraints.maxWidth, seed: _seed, spacing: _spacing);
  }
}
