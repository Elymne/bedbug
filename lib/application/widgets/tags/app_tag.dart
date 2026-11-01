import 'package:bedbug/application/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rayon des coins d'un tag.
const double _kRadius = 20;

/// Épaisseur de la bordure d'un tag.
const double _kBorderWidth = 1;

/// Opacité des couleurs sur le fond d'un tag.
const double _kBackgroundOpacity = 0.12;

/// Opacité des couleurs sur la bordure d'un tag.
const double _kBorderOpacity = 0.4;

/// Tag visuel réutilisable avec fond coloré et bordure arrondie.
///
/// Utilisé pour afficher des labels catégorisés (permissions, statuts, etc.).
/// Avec plusieurs couleurs, le texte, le fond et la bordure suivent le même dégradé.
class AppTag extends ConsumerWidget {
  /// Crée un [AppTag].
  ///
  /// - [label] : texte affiché dans le tag.
  /// - [colors] : couleur d'accentuation, ou couleurs du dégradé, de gauche à droite. Au moins une.
  const AppTag({super.key, required this.label, required this.colors});

  /// Texte affiché dans le tag.
  final String label;

  /// Couleur d'accentuation, ou couleurs du dégradé, de gauche à droite.
  final List<Color> colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Un dégradé demande deux couleurs : une couleur seule devient un dégradé uni, sans cas à part à dessiner.
    final gradient = LinearGradient(colors: colors.length == 1 ? [colors.first, colors.first] : colors);

    return CustomPaint(
      painter: _TagPainter(gradient),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: ShaderMask(
          shaderCallback: gradient.createShader,
          blendMode: BlendMode.srcIn,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.onDark, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

/// Dessine le fond et la bordure d'un [AppTag].
///
/// Une bordure de `Container` ne prend qu'une couleur : elle ne peut pas suivre un dégradé.
class _TagPainter extends CustomPainter {
  /// Crée un [_TagPainter].
  ///
  /// - [gradient] : dégradé du tag, à pleine opacité.
  const _TagPainter(this.gradient);

  /// Dégradé du tag, à pleine opacité.
  final LinearGradient gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = RRect.fromRectAndRadius(rect, const Radius.circular(_kRadius));
    canvas.drawRRect(background, Paint()..shader = gradient.scale(_kBackgroundOpacity).createShader(rect));
    canvas.drawRRect(
      background.deflate(_kBorderWidth / 2),
      Paint()
        ..shader = gradient.scale(_kBorderOpacity).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _kBorderWidth,
    );
  }

  @override
  bool shouldRepaint(_TagPainter oldDelegate) {
    return oldDelegate.gradient != gradient;
  }
}
