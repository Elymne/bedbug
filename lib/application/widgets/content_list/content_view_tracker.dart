import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Temps qu'un contenu doit rester à l'écran pour compter comme vu.
///
/// Sans ce délai, un défilement rapide marquerait comme vus des contenus que personne n'a eu le temps de regarder.
const Duration _kViewDuration = Duration(seconds: 1);

/// Part de [ContentViewTracker.child] qui doit être à l'écran pour compter.
///
/// Rapportée à la liste plutôt qu'au contenu quand il est plus grand qu'elle : il ne tiendrait jamais à l'écran.
const double _kVisibleRatio = 0.5;

/// Prévient quand [child], élément d'une liste, est resté assez longtemps à l'écran pour avoir été vu.
class ContentViewTracker extends ConsumerStatefulWidget {
  /// Crée un [ContentViewTracker].
  ///
  /// - [onViewed] : appelé une seule fois, quand [child] a été vu.
  /// - [child] : élément de la liste à surveiller.
  const ContentViewTracker({super.key, required this.onViewed, required this.child});

  /// Appelé une seule fois, quand [child] a été vu.
  final VoidCallback onViewed;

  /// Élément de la liste à surveiller.
  final Widget child;

  @override
  ConsumerState<ContentViewTracker> createState() => _State();
}

class _State extends ConsumerState<ContentViewTracker> {
  /// Défilement de la liste, écouté pour savoir quand [ContentViewTracker.child] entre et sort de l'écran.
  ScrollPosition? _position;

  /// Décompte en cours pendant que l'élément est à l'écran.
  Timer? _viewTimer;

  /// Indique si une vérification est déjà prévue à la fin de l'image en cours.
  bool _isCheckScheduled = false;

  /// Indique si l'élément a déjà été signalé comme vu.
  bool _isViewed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _position?.removeListener(_scheduleCheck);
    _position = Scrollable.of(context).position..addListener(_scheduleCheck);
    _scheduleCheck();
  }

  @override
  void dispose() {
    _viewTimer?.cancel();
    _position?.removeListener(_scheduleCheck);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  /// Prévoit une vérification une fois l'image dessinée, quand les positions sont à jour.
  void _scheduleCheck() {
    if (_isCheckScheduled || _isViewed) {
      return;
    }
    _isCheckScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _isCheckScheduled = false;
      _updateTimer();
    });
  }

  /// Lance le décompte quand l'élément est à l'écran, et l'annule quand il en sort.
  void _updateTimer() {
    if (!mounted || _isViewed) {
      return;
    }
    if (!_isVisible()) {
      _viewTimer?.cancel();
      _viewTimer = null;
      return;
    }
    _viewTimer ??= Timer(_kViewDuration, _onViewed);
  }

  /// Retourne `true` si une part suffisante de l'élément est à l'écran.
  bool _isVisible() {
    final element = context.findRenderObject();
    final viewport = Scrollable.of(context).context.findRenderObject();
    if (element is! RenderBox || viewport is! RenderBox || !element.hasSize || !viewport.hasSize) {
      return false;
    }
    final top = element.localToGlobal(Offset.zero, ancestor: viewport).dy;
    final visibleHeight = min(top + element.size.height, viewport.size.height) - max(top, 0);
    return visibleHeight >= min(element.size.height, viewport.size.height) * _kVisibleRatio;
  }

  /// Signale que l'élément a été vu, et cesse de le surveiller.
  void _onViewed() {
    _isViewed = true;
    _position?.removeListener(_scheduleCheck);
    widget.onViewed();
  }
}
