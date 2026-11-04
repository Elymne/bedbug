import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/search/flair_suggestion_tile/flair_suggestion_tile.widget.dart';
import 'package:bedbug/application/screens/search/search_suggestions/search_suggestions.notifier.dart';
import 'package:bedbug/application/screens/search/signature_suggestion_tile/signature_suggestion_tile.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Suggestions affichées sous le champ de recherche pendant la frappe : les flairs, puis les signatures.
///
/// Seul widget de l'écran de recherche à observer les suggestions : chaque frappe ne reconstruit que la liste, pas le
/// champ. Un tap sur un flair ouvre les résultats de ce flair exact ; un tap sur une signature ouvre sa page.
class SearchSuggestions extends ConsumerWidget {
  /// Crée un [SearchSuggestions].
  const SearchSuggestions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchSuggestionsNotifierWatcher = ref.watch(searchSuggestionsNotifierProvider);
    final flairs = searchSuggestionsNotifierWatcher.value?.flairs ?? const [];
    final signatures = searchSuggestionsNotifierWatcher.value?.signatures ?? const [];

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        for (final flair in flairs)
          FlairSuggestionTile(
            suggestion: flair,
            onTap: () {
              context.push(Uri(path: searchResultsPath, queryParameters: {searchFlairParam: flair.flair}).toString());
            },
          ),
        for (final signature in signatures)
          SignatureSuggestionTile(
            signature: signature,
            onTap: () => context.push('$signaturesPath/${Uri.encodeComponent(signature.id)}'),
          ),
      ],
    );
  }
}
