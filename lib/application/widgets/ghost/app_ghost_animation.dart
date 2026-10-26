import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Marge, en pixels, autour de la zone visible dans laquelle une animation est considérée à l'écran.
///
/// L'animation repart un peu avant d'entrer à l'écran : on ne la voit jamais
/// démarrer en arrivant.
const double _kVisibilityMargin = 50;

/// Décalages courants des deux couches d'un effet ghost.
class GhostOffsets {
  /// Crée des [GhostOffsets].
  ///
  /// - [ghost] : décalage de la couche ghost (colorée), la plus mobile.
  /// - [main] : décalage de la couche principale, plus discret.
  const GhostOffsets({required this.ghost, required this.main});

  /// Décalage de la couche ghost (colorée).
  final Offset ghost;

  /// Décalage de la couche principale.
  final Offset main;
}

/// Moteur d'animation d'un effet ghost : produit, à chaque frame, les décalages des couches ghost et principale.
///
/// Ne dessine rien lui-même : [builder] compose les couches comme il
/// l'entend (deux couches dans `AppGhostEffect`, plusieurs couches empilées
/// dans une réaction). Les controllers ont des durées premières entre elles :
/// le mouvement ne se répète jamais à l'identique.
///
/// Pensé pour les longues listes : chaque animation est redessinée seule
/// (sans redessiner la page), et se met en pause dès qu'elle sort de la zone
/// visible de son défilement.
class AppGhostAnimation extends ConsumerStatefulWidget {
  /// Crée un [AppGhostAnimation].
  ///
  /// - [builder] : compose les couches à partir des décalages courants, `null` quand l'animation est arrêtée.
  /// - [isAnimating] : `true` pour lancer l'animation.
  /// - [speed] : multiplicateur de vitesse (défaut 1.0 — plus grand = plus rapide).
  /// - [intensity] : amplitude des décalages en pixels (défaut 1.0).
  const AppGhostAnimation({
    super.key,
    required this.builder,
    required this.isAnimating,
    this.speed = 1.0,
    this.intensity = 1.0,
  });

  /// Compose les couches à partir des décalages courants, `null` quand l'animation est arrêtée.
  final Widget Function(BuildContext context, GhostOffsets? offsets) builder;

  /// Indique si l'animation est active.
  final bool isAnimating;

  /// Multiplicateur de vitesse des controllers.
  final double speed;

  /// Amplitude des décalages en pixels.
  final double intensity;

  @override
  ConsumerState<AppGhostAnimation> createState() => _State();
}

class _State extends ConsumerState<AppGhostAnimation> with TickerProviderStateMixin {
  /// Oscillation X de la couche ghost.
  late final AnimationController _ghostX = AnimationController(duration: _duration(850), vsync: this);

  /// Oscillation Y de la couche ghost.
  late final AnimationController _ghostY = AnimationController(duration: _duration(1130), vsync: this);

  /// Oscillation X de la couche principale.
  late final AnimationController _mainX = AnimationController(duration: _duration(970), vsync: this);

  /// Oscillation Y de la couche principale.
  late final AnimationController _mainY = AnimationController(duration: _duration(1370), vsync: this);

  /// Tous les controllers.
  late final List<AnimationController> _controllers = [_ghostX, _ghostY, _mainX, _mainY];

  /// Défilement le plus proche, écouté pour savoir si l'animation est à l'écran. `null` hors défilement.
  ScrollableState? _scrollable;

  /// Indique si l'animation est dans la zone visible de son défilement (toujours `true` hors défilement).
  bool _isOnScreen = true;

  @override
  void initState() {
    super.initState();
    if (widget.isAnimating) {
      _startAnimations();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable?.position == _scrollable?.position) {
      return;
    }
    _scrollable?.position.removeListener(_updateVisibility);
    _scrollable = scrollable;
    _scrollable?.position.addListener(_updateVisibility);
    // La position à l'écran n'est connue qu'après la mise en page.
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateVisibility());
  }

  @override
  void didUpdateWidget(AppGhostAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.speed != oldWidget.speed) {
      _applySpeed(isRunning: widget.isAnimating && oldWidget.isAnimating);
    }
    if (widget.isAnimating && !oldWidget.isAnimating) {
      _startAnimations();
      return;
    }
    if (!widget.isAnimating && oldWidget.isAnimating) {
      _stopAnimations();
    }
  }

  @override
  void dispose() {
    _scrollable?.position.removeListener(_updateVisibility);
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAnimating) {
      return widget.builder(context, null);
    }

    // Isole le dessin : à chaque frame, seule cette animation est redessinée,
    // pas toute la page qui la contient.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge(_controllers),
        builder: (context, _) {
          final offsets = GhostOffsets(
            ghost: Offset(3.2 * widget.intensity * _ghostX.value, 2.0 * widget.intensity * _ghostY.value),
            main: Offset(1.2 * widget.intensity * _mainX.value, 0.7 * widget.intensity * _mainY.value),
          );
          return widget.builder(context, offsets);
        },
      ),
    );
  }

  /// Retourne la durée de base [milliseconds] ajustée par [AppGhostAnimation.speed].
  ///
  /// - [milliseconds] : durée d'une oscillation à vitesse normale.
  Duration _duration(int milliseconds) {
    return Duration(milliseconds: (milliseconds / widget.speed).round());
  }

  /// Recalcule la durée des controllers d'après [AppGhostAnimation.speed].
  ///
  /// Les durées sont fixées à la création des controllers : sans ce recalcul,
  /// changer la vitesse en direct (curseur de réglage) n'aurait aucun effet.
  /// Une boucle déjà lancée est relancée depuis sa position courante pour
  /// prendre la nouvelle durée en compte, sans saut visible.
  ///
  /// - [isRunning] : `true` si l'animation tournait déjà avant le changement.
  void _applySpeed({required bool isRunning}) {
    _ghostX.duration = _duration(850);
    _ghostY.duration = _duration(1130);
    _mainX.duration = _duration(970);
    _mainY.duration = _duration(1370);
    if (isRunning) {
      _startAnimations();
    }
  }

  /// Démarre tous les controllers en boucle alternée, sauf si l'animation est hors écran.
  ///
  /// Hors écran, elle démarrera d'elle-même en y revenant (voir [_updateVisibility]).
  void _startAnimations() {
    if (!_isOnScreen) {
      return;
    }
    for (final controller in _controllers) {
      controller.repeat(reverse: true);
    }
  }

  /// Met en pause tous les controllers, sans les remettre à zéro.
  ///
  /// L'animation reprend là où elle s'était arrêtée, sans saut visible.
  void _pauseAnimations() {
    for (final controller in _controllers) {
      controller.stop();
    }
  }

  /// Arrête et remet à zéro tous les controllers.
  void _stopAnimations() {
    for (final controller in _controllers) {
      controller
        ..stop()
        ..reset();
    }
  }

  /// Met l'animation en pause quand elle sort de la zone visible de son défilement, et la relance quand elle y revient.
  ///
  /// Une liste peut contenir des dizaines d'animations (réactions,
  /// signatures) : faire tourner celles qu'on ne voit pas coûterait autant
  /// que celles qu'on voit, pour rien. Appelée à chaque mouvement du
  /// défilement ; ne relance ou ne met en pause que si la visibilité change.
  void _updateVisibility() {
    if (!mounted) {
      return;
    }
    final box = context.findRenderObject();
    final viewport = _scrollable?.context.findRenderObject();
    if (box is! RenderBox || viewport is! RenderBox || !box.hasSize || !viewport.hasSize) {
      return;
    }
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final viewportRect = viewport.localToGlobal(Offset.zero) & viewport.size;
    final isOnScreen = rect.overlaps(viewportRect.inflate(_kVisibilityMargin));
    if (isOnScreen == _isOnScreen) {
      return;
    }
    _isOnScreen = isOnScreen;
    if (!widget.isAnimating) {
      return;
    }
    if (isOnScreen) {
      _startAnimations();
      return;
    }
    _pauseAnimations();
  }
}
