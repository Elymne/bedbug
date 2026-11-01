import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/texts/app_prefixed_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Ligne du menu des paramètres : une icône, un titre et une description, menant à la page d'un réglage.
class SettingsMenuTile extends ConsumerWidget {
  /// Crée un [SettingsMenuTile].
  ///
  /// - [icon] : icône affichée devant le titre.
  /// - [title] : nom du réglage.
  /// - [subtitle] : description affichée sous le titre.
  /// - [path] : chemin de la page du réglage.
  /// - [subtitlePrefix] : préfixe optionnel affiché en couleur primaire devant [subtitle] (ex. `s/`).
  const SettingsMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.path,
    this.subtitlePrefix,
  });

  /// Icône affichée devant le titre.
  final IconData icon;

  /// Nom du réglage.
  final String title;

  /// Description affichée sous le titre.
  final String subtitle;

  /// Chemin de la page du réglage.
  final String path;

  /// Préfixe optionnel affiché en couleur primaire devant [subtitle] (voir `AppPrefixes`).
  final String? subtitlePrefix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(icon, color: AppColors.onLight),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onLight),
      ),
      subtitle: AppPrefixedText(
        prefix: subtitlePrefix ?? '',
        text: subtitle,
        style: const TextStyle(fontSize: 13, color: AppColors.disabled),
      ),
      onTap: () => context.push(path),
    );
  }
}
