import 'package:bedbug/application/screens/home/home_collapsible_bar/home_collapsible_bar.notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Barre de la home qui sort de l'écran au scroll, comme la searchbar et la navbar.
///
/// Observe la distance de sortie d'écran mise à jour à chaque pixel de scroll : isolée dans ce widget, elle ne
/// reconstruit que le cadre de la barre, jamais son contenu [child] ni le reste de la page.
class HomeCollapsibleBar extends ConsumerWidget {
  /// Crée un [HomeCollapsibleBar].
  ///
  /// - [height] : hauteur de la barre entièrement visible.
  /// - [alignment] : bord de la barre qui reste visible le plus longtemps, la portion opposée étant clippée en
  ///   premier.
  /// - [child] : contenu de la barre.
  const HomeCollapsibleBar({super.key, required this.height, required this.alignment, required this.child});

  /// Hauteur de la barre entièrement visible.
  final double height;

  /// Bord de la barre qui reste visible le plus longtemps.
  final Alignment alignment;

  /// Contenu de la barre.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hiddenOffset = ref.watch(homeCollapsibleBarNotifierProvider);
    final hiddenExtent = hiddenOffset.clamp(0.0, height);

    return ClipRect(
      child: SizedBox(
        height: height - hiddenExtent,
        child: OverflowBox(
          minHeight: height,
          maxHeight: height,
          alignment: alignment,
          child: SizedBox(height: height, child: child),
        ),
      ),
    );
  }
}
