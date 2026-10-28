import 'package:bedbug/application/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fond neutre occupant la place d'un média : pendant son chargement, en cas d'erreur, ou quand il est masqué.
///
/// Garde la mise en page stable : un média qui n'est pas (encore) affiché
/// occupe exactement la place qu'il aurait prise.
class AppMediaPlaceholder extends ConsumerWidget {
  /// Crée un [AppMediaPlaceholder].
  ///
  /// - [icon] : icône centrale.
  /// - [label] : texte optionnel sous l'icône (domaine masqué, erreur…).
  /// - [isDark] : `true` pour un fond sombre, celui des vidéos.
  const AppMediaPlaceholder({super.key, required this.icon, this.label, this.isDark = false});

  /// Icône centrale.
  final IconData icon;

  /// Texte optionnel sous l'icône.
  final String? label;

  /// Indique si le fond est sombre, comme celui d'une vidéo.
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foregroundColor = isDark ? AppColors.onDark : AppColors.disabled;

    return ColoredBox(
      color: isDark ? AppColors.onLightDeep : AppColors.border,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Icon(icon, color: foregroundColor),
              if (label != null)
                Text(
                  label!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: foregroundColor),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
