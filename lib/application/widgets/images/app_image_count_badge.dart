import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/widgets/icons/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pastille sombre superposée à une image, signalant qu'elle fait partie d'une série.
///
/// Affichée par-dessus l'image d'un contenu qui en regroupe plusieurs, pour
/// que l'utilisateur sache qu'il y a d'autres images à voir (tuile) ou où il
/// en est dans la série (carrousel du détail).
class AppImageCountBadge extends ConsumerWidget {
  /// Crée un [AppImageCountBadge].
  ///
  /// - [label] : texte affiché à côté de l'icône (ex. `4` ou `2/4`).
  const AppImageCountBadge({super.key, required this.label});

  /// Texte affiché à côté de l'icône.
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          const AppIcon(AppIcons.collections, size: 14, color: AppColors.onDark),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.onDark)),
        ],
      ),
    );
  }
}
