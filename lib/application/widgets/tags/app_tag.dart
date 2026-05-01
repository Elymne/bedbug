import 'package:flutter/material.dart';

/// Tag visuel réutilisable avec fond coloré et bordure arrondie.
///
/// Utilisé pour afficher des labels catégorisés (permissions, statuts, etc.).
class AppTag extends StatelessWidget {
  /// Crée un [AppTag] avec le [label] et la [color] d'accentuation fournis.
  const AppTag({required this.label, required this.color, super.key});

  /// Texte affiché dans le tag.
  final String label;

  /// Couleur d'accentuation du tag (texte et bordure).
  /// Le fond est dérivé avec une opacité réduite.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
