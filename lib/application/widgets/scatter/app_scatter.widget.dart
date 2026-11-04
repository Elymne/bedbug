import 'package:bedbug/application/widgets/scatter/render_scatter.dart';
import 'package:flutter/widgets.dart';

/// Disperse ses enfants au hasard sur toute la largeur disponible, sans qu'aucun ne chevauche un autre.
///
/// Chaque enfant garde sa taille naturelle (bornée par la largeur) : un long
/// message prend plus de place qu'un bedbug seul, et le placement en tient
/// compte. La hauteur du widget est celle qu'occupent les enfants une fois
/// placés. Les positions sont tirées de [seed] : elles restent identiques
/// d'une reconstruction à l'autre tant que la graine et les enfants ne
/// changent pas. La largeur doit être bornée (dans une colonne ou un
/// défilement vertical, par exemple).
class AppScatter extends MultiChildRenderObjectWidget {
  /// Crée un [AppScatter].
  ///
  /// - [children] : widgets à disperser.
  /// - [seed] : graine du tirage aléatoire des positions.
  /// - [spacing] : espace minimal laissé entre deux enfants (défaut 12).
  const AppScatter({super.key, required super.children, required this.seed, this.spacing = 12});

  /// Graine du tirage aléatoire des positions.
  final int seed;

  /// Espace minimal laissé entre deux enfants.
  final double spacing;

  @override
  RenderScatter createRenderObject(BuildContext context) {
    return RenderScatter(seed: seed, spacing: spacing);
  }

  @override
  void updateRenderObject(BuildContext context, RenderScatter renderObject) {
    renderObject
      ..seed = seed
      ..spacing = spacing;
  }
}
