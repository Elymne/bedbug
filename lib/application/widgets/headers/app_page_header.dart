import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/widgets/icons/app_icon.dart';
import 'package:bedbug/application/widgets/texts/app_prefixed_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// En-tête standard d'une page avec titre et bouton retour optionnel.
class AppPageHeader extends ConsumerWidget {
  /// Crée un [AppPageHeader].
  ///
  /// - [title] : titre affiché dans l'en-tête.
  /// - [onBack] : callback déclenché lors du tap sur le bouton retour.
  ///   Si `null`, aucun bouton retour n'est affiché.
  /// - [titlePrefix] : préfixe optionnel affiché en couleur primaire devant le titre (ex. `f/`).
  const AppPageHeader({super.key, required this.title, this.onBack, this.titlePrefix});

  /// Titre de la page.
  final String title;

  /// Préfixe optionnel affiché en couleur primaire devant [title] (voir `AppPrefixes`).
  final String? titlePrefix;

  /// Callback déclenché lors du tap sur le bouton retour.
  ///
  /// `null` = pas de bouton retour.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppValues.baseMargin, vertical: 12),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              icon: const AppIcon(AppIcons.arrowBack, color: AppColors.onLight),
            ),
          AppPrefixedText(
            prefix: titlePrefix ?? '',
            text: title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.onLight),
          ),
        ],
      ),
    );
  }
}
