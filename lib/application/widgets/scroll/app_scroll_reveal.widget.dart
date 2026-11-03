import 'package:bedbug/application/widgets/scroll/scroll_visibility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Durée de l'apparition, assez longue pour laisser le rebond se jouer.
const Duration _kRevealDuration = Duration(milliseconds: 700);

/// Durée de la disparition, plus courte : l'élément s'efface pendant qu'il sort.
const Duration _kHideDuration = Duration(milliseconds: 250);

/// Taille de départ de l'apparition, et taille d'arrivée de la disparition.
const double _kHiddenScale = 0.4;

/// Fait apparaître [child] avec un rebond quand il devient entièrement visible dans son défilement, et le fait disparaître en fondu dès qu'il commence à en sortir.
///
/// L'apparition combine un fondu et un zoom élastique, qui dépasse
/// légèrement sa taille avant de s'y poser. La disparition est un fondu
/// rapide accompagné d'un léger rétrécissement. Hors défilement, [child] est
/// affiché tel quel. [child] garde sa place pendant les deux animations :
/// seul son rendu change, jamais la mise en page autour de lui.
class AppScrollReveal extends ConsumerStatefulWidget {
  /// Crée un [AppScrollReveal].
  ///
  /// - [child] : widget à faire apparaître et disparaître.
  const AppScrollReveal({super.key, required this.child});

  /// Widget à faire apparaître et disparaître.
  final Widget child;

  @override
  ConsumerState<AppScrollReveal> createState() => _State();
}

class _State extends ConsumerState<AppScrollReveal> with SingleTickerProviderStateMixin {
  /// Progression de l'apparition : 0 caché, 1 entièrement apparu.
  late final AnimationController _controller = AnimationController(
    duration: _kRevealDuration,
    reverseDuration: _kHideDuration,
    vsync: this,
  );

  /// Opacité : rapide à l'apparition (le rebond se voit ensuite), fondu simple à la disparition.
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.4, curve: Curves.easeOut),
    reverseCurve: Curves.easeIn,
  );

  /// Échelle : rebond élastique à l'apparition, léger rétrécissement à la disparition.
  late final Animation<double> _scale = Tween<double>(
    begin: _kHiddenScale,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut, reverseCurve: Curves.easeIn));

  /// Défilement le plus proche, écouté pour savoir si [AppScrollReveal.child] est à l'écran. `null` hors défilement.
  ScrollableState? _scrollable;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable?.position != _scrollable?.position) {
      _scrollable?.position.removeListener(_updateVisibility);
      _scrollable = scrollable;
      _scrollable?.position.addListener(_updateVisibility);
    }
    // La position à l'écran n'est connue qu'après la mise en page. Vérifiée
    // aussi hors défilement : c'est elle qui affiche alors l'élément.
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateVisibility());
  }

  @override
  void dispose() {
    _scrollable?.position.removeListener(_updateVisibility);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }

  /// Lance l'apparition quand l'élément devient entièrement visible, et la disparition dès qu'il ne l'est plus.
  ///
  /// Appelée à chaque mouvement du défilement : une animation déjà en cours
  /// dans le bon sens n'est pas relancée.
  void _updateVisibility() {
    if (!mounted) {
      return;
    }
    final scrollable = _scrollable;
    if (scrollable == null) {
      _controller.value = 1;
      return;
    }
    final visibility = scrollVisibilityOf(context, scrollable);
    if (visibility == null) {
      return;
    }
    if (visibility == ScrollVisibility.full) {
      if (_controller.status != AnimationStatus.forward && _controller.status != AnimationStatus.completed) {
        _controller.forward();
      }
      return;
    }
    if (_controller.status != AnimationStatus.reverse && _controller.status != AnimationStatus.dismissed) {
      _controller.reverse();
    }
  }
}
