import 'package:bedbug/application/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rayon des coins arrondis de la section.
const _kBorderRadius = 16.0;

/// Section repliable en carte : un en-tête cliquable qui déplie [child] en dessous.
///
/// Sert de brique aux pages d'options : chaque réglage vit dans sa propre
/// section, repliée par défaut, pour garder la page lisible à mesure que les
/// réglages s'ajoutent.
class AppExpandableSection extends ConsumerWidget {
  /// Crée un [AppExpandableSection].
  ///
  /// - [title] : titre affiché dans l'en-tête.
  /// - [icon] : icône affichée devant le titre.
  /// - [child] : contenu affiché une fois la section dépliée.
  /// - [subtitle] : texte secondaire optionnel sous le titre.
  const AppExpandableSection({super.key, required this.title, required this.icon, required this.child, this.subtitle});

  /// Titre affiché dans l'en-tête.
  final String title;

  /// Icône affichée devant le titre.
  final IconData icon;

  /// Contenu affiché une fois la section dépliée.
  final Widget child;

  /// Texte secondaire optionnel sous le titre.
  final String? subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const shape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(_kBorderRadius)));
    Widget? subtitleWidget;
    if (subtitle != null) {
      subtitleWidget = Text(subtitle!, style: const TextStyle(fontSize: 13, color: AppColors.disabled));
    }

    return Material(
      color: AppColors.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: shape,
        collapsedShape: shape,
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.onLight,
        leading: Icon(icon, color: AppColors.onLight),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onLight),
        ),
        subtitle: subtitleWidget,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [child],
      ),
    );
  }
}
