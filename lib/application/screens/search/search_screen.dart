import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/fields/content_search_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Écran de recherche dédié.
///
/// Accessible depuis le faux champ de recherche de la home page, à la
/// manière de Reddit : le champ y est repositionné à l'identique en haut de
/// l'écran, avec le clavier ouvert automatiquement. Aucun résultat n'est
/// encore affiché en dessous.
class SearchScreen extends ConsumerWidget {
  /// Crée un [SearchScreen].
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      backgroundColor: AppColors.surfaceDark,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: ContentSearchInput(hintText: 'Rechercher…', autofocus: true, isDark: true),
        ),
      ),
    );
  }
}
