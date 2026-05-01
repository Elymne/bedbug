import 'dart:math';

import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Type d'affichage du [AppText].
enum AppTextType {
  /// Texte rouge avec animation de tremblement amorti jouée une seule fois.
  error,

  /// Texte bleu avec animation de fondu en boucle entre 40 % et 100 % d'opacité.
  info,
}

/// Widget d'affichage de messages avec animation selon le [type].
///
/// En mode [AppTextType.error] : texte rouge, animation de tremblement amorti
/// jouée une seule fois. Pour rejouer l'animation sur une nouvelle erreur,
/// passer une nouvelle [Key] (ex. `key: ValueKey(errorCounter)`).
///
/// En mode [AppTextType.info] : texte bleu, animation de fondu doux en boucle
/// oscillant entre 40 % et 100 % d'opacité.
class AppText extends StatefulWidget {
  /// Crée un [AppText].
  const AppText({super.key, this.message, this.type = AppTextType.error});

  /// Message à afficher. Utilise la valeur localisée par défaut si non fourni.
  final String? message;

  /// Type d'affichage.
  final AppTextType type;

  @override
  State<AppText> createState() => _State();
}

class _State extends State<AppText> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    switch (widget.type) {
      case AppTextType.error:
        _controller = AnimationController(
          duration: const Duration(milliseconds: 700),
          vsync: this,
        )..forward();
        _animation = _controller;
      case AppTextType.info:
        _controller = AnimationController(
          duration: const Duration(milliseconds: 1400),
          vsync: this,
        )..repeat(reverse: true);
        _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (widget.type) {
      case AppTextType.error:
        final message = widget.message ?? "l10n.errorDefaultText";
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) => Transform.translate(
            offset: Offset(
              8.0 * (1.0 - _controller.value) * sin(_controller.value * pi * 6),
              0,
            ),
            child: child,
          ),
          child: Text(message, style: const TextStyle(color: Colors.red)),
        );
      case AppTextType.info:
        final message = widget.message ?? "l10n.infoDefaultText";
        return FadeTransition(
          opacity: _animation,
          child: Text(message, style: const TextStyle(color: Colors.blue)),
        );
    }
  }
}
