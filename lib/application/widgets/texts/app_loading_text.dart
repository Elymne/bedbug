import 'package:flutter/material.dart';

/// Widget de chargement affichant un texte dont les lettres apparaissent
/// en fondu une à une de gauche à droite, en boucle continue.
class AppLoadingText extends StatefulWidget {
  /// Crée un [AppLoadingText].
  const AppLoadingText({super.key, this.text});

  /// Texte à afficher. Utilise la valeur localisée par défaut si non fourni.
  final String? text;

  @override
  State<AppLoadingText> createState() => _AppLoadingTextState();
}

class _AppLoadingTextState extends State<AppLoadingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 3000),
    vsync: this,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Calcule l'opacité de la lettre à [index] pour la progression courante.
  ///
  /// [total] est le nombre total de lettres dans le texte.
  double _opacity(int index, int total) {
    final progress = _controller.value;
    const appearPhase = 0.65;
    const fadeOutStart = 0.82;

    final start = (index / total) * appearPhase;
    final end = start + (appearPhase / total).clamp(0.0, 0.12);

    if (progress < start) return 0.0;
    if (progress < end) return (progress - start) / (end - start);
    if (progress < fadeOutStart) return 1.0;
    return 1.0 - (progress - fadeOutStart) / (1.0 - fadeOutStart);
  }

  @override
  Widget build(BuildContext context) {
    final text =
        widget.text ?? "AppLocalizations.of(context)!.loadingDefaultText";

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < text.length; i++)
            Opacity(opacity: _opacity(i, text.length), child: Text(text[i])),
        ],
      ),
    );
  }
}
