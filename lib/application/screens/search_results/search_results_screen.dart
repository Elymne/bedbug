import 'package:bedbug/application/notifiers/content_author_notifier.dart';
import 'package:bedbug/application/screens/search_results/search_criteria.dart';
import 'package:bedbug/application/screens/search_results/search_results_notifier.dart';
import 'package:bedbug/application/style/app_prefixes.dart';
import 'package:bedbug/application/widgets/content_list/content_list_view.dart';
import 'package:bedbug/application/widgets/headers/app_page_header.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
class SearchResultsScreen extends ConsumerWidget {
  /// Crée un [SearchResultsScreen].
  ///
  /// - [criteria] : critère de recherche dont on affiche les résultats.
  const SearchResultsScreen({super.key, required this.criteria});

  /// Critère de recherche dont on affiche les résultats.
  final SearchCriteria criteria;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.loc;
    final searchResultsNotifierWatcher = ref.watch(searchResultsNotifierProvider(criteria));
    final title = switch (criteria) {
      FlairSearchCriteria(:final flair) => flair,
      SignatureSearchCriteria(:final signatureId) => _signaturePseudo(ref, signatureId),
      QuerySearchCriteria(:final query) => l10n.searchResultsQueryTitle(query),
    };
    final titlePrefix = switch (criteria) {
      FlairSearchCriteria() => AppPrefixes.flair,
      SignatureSearchCriteria() => AppPrefixes.signature,
      QuerySearchCriteria() => null,
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(title: title, titlePrefix: titlePrefix, onBack: context.pop),
            Expanded(
              child: searchResultsNotifierWatcher.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(child: Text(l10n.homeGetContentsUnknown)),
                data: (state) => ContentListView(
                  contents: state.contents,
                  emptyChild: Center(child: Text(state.failureMessage ?? l10n.searchResultsEmpty)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pseudo de la signature [signatureId], affiché en titre derrière le préfixe `s/`.
  ///
  /// Le pseudo est relu depuis la signature ; le temps de la charger, le titre
  /// se contente du préfixe.
  String _signaturePseudo(WidgetRef ref, String signatureId) {
    final contentAuthorNotifierWatcher = ref.watch(contentAuthorNotifierProvider(signatureId));
    return contentAuthorNotifierWatcher.value?.pseudo ?? '';
  }
}
