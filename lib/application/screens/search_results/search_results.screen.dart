import 'package:bedbug/application/notifiers/search_results.notifier.dart';
import 'package:bedbug/application/screens/search_results/search_results_header/search_results_header.widget.dart';
import 'package:bedbug/application/screens/search_results/search_results_list/search_results_list.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Page listant les contenus correspondant à une recherche.
///
/// Ouverte depuis l'écran de recherche, soit par le choix d'un flair parmi
/// les suggestions ([FlairSearchCriteria]), soit par la validation directe de
/// la saisie ([QuerySearchCriteria]). Le retour ramène à l'écran de
/// recherche, avec la saisie conservée.
///
/// Une signature choisie ouvre, elle, sa page dédiée (`SignatureScreen`), qui
/// réutilise le même notifier avec un [SignatureSearchCriteria] ; ce critère
/// reste géré ici pour que le `switch` sur [SearchCriteria] soit exhaustif.
///
/// Page statique : l'en-tête et la liste observent chacun leur état.
class SearchResultsScreen extends ConsumerWidget {
  /// Crée un [SearchResultsScreen].
  ///
  /// - [criteria] : critère de recherche dont on affiche les résultats.
  const SearchResultsScreen({super.key, required this.criteria});

  /// Critère de recherche dont on affiche les résultats.
  final SearchCriteria criteria;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SearchResultsHeader(criteria: criteria),
            Expanded(child: SearchResultsList(criteria: criteria)),
          ],
        ),
      ),
    );
  }
}
