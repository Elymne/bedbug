import 'package:bedbug/application/notifiers/search_results.notifier.dart';
import 'package:bedbug/application/widgets/content_list/content_list_view.widget.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Liste des contenus correspondant à une recherche, ou un message si aucun ne correspond.
///
/// Seul widget de la page de résultats à observer la recherche : son chargement ne reconstruit pas l'en-tête.
class SearchResultsList extends ConsumerWidget {
  /// Crée un [SearchResultsList].
  ///
  /// - [criteria] : critère de recherche dont on affiche les résultats.
  const SearchResultsList({super.key, required this.criteria});

  /// Critère de recherche dont on affiche les résultats.
  final SearchCriteria criteria;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResultsNotifierWatcher = ref.watch(searchResultsNotifierProvider(criteria));
    final l10n = context.loc;

    return searchResultsNotifierWatcher.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(l10n.homeGetContentsUnknown)),
      data: (state) {
        return ContentListView(
          contents: state.contents,
          emptyChild: Center(child: Text(state.failureMessage ?? l10n.searchResultsEmpty)),
        );
      },
    );
  }
}
