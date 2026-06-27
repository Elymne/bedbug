import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// En-tête standard d'une page avec titre et bouton retour optionnel.
class AppPageHeader extends ConsumerWidget {
  /// Crée un [AppPageHeader].
  ///
  /// - [title] : titre affiché dans l'en-tête.
  /// - [onBack] : callback déclenché lors du tap sur le bouton retour.
  ///   Si `null`, aucun bouton retour n'est affiché.
  const AppPageHeader({super.key, required this.title, this.onBack});

  /// Titre de la page.
  final String title;

  /// Callback déclenché lors du tap sur le bouton retour.
  ///
  /// `null` = pas de bouton retour.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppValues.baseMargin,
        vertical: 12,
      ),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: AppColors.onLight),
            ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.onLight,
            ),
          ),
        ],
      ),
    );
  }
}
