import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/search/search_suggestions_notifier.dart';
import 'package:bedbug/application/screens/search/widgets/flair_suggestion_tile.dart';
import 'package:bedbug/application/screens/search/widgets/user_suggestion_tile.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/fields/content_search_input.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Écran de recherche dédié.
///
/// Accessible depuis le faux champ de recherche de la home page, à la
/// manière de Reddit : le champ y est repositionné à l'identique en haut de
/// l'écran, avec le clavier ouvert automatiquement. Pendant la frappe, les
/// flairs existants puis les utilisateurs connus commençant par la saisie
/// sont proposés en dessous :
/// - un tap sur un flair ouvre les résultats de ce flair exact ;
/// - un tap sur un utilisateur ouvre les contenus qu'il a signés ;
/// - valider la saisie au clavier lance une recherche globale (titre et flair).
class SearchScreen extends ConsumerWidget {
  /// Crée un [SearchScreen].
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ContentSearchInput(
                hintText: context.loc.searchHint,
                autofocus: true,
                isDark: true,
                onChanged: (text) => ref.read(searchSuggestionsNotifierProvider.notifier).search(text),
                onSubmitted: (text) {
                  final query = text.trim();
                  if (query.isEmpty) {
                    return;
                  }
                  context.push(Uri(path: searchResultsPath, queryParameters: {searchQueryParam: query}).toString());
                },
              ),
            ),
            Expanded(
              child: Consumer(
                builder: (context, ref, _) {
                  final searchSuggestionsNotifierWatcher = ref.watch(searchSuggestionsNotifierProvider);
                  final flairs = searchSuggestionsNotifierWatcher.value?.flairs ?? const [];
                  final users = searchSuggestionsNotifierWatcher.value?.users ?? const [];
                  return ListView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      for (final flair in flairs)
                        FlairSuggestionTile(
                          suggestion: flair,
                          onTap: () => context.push(
                            Uri(path: searchResultsPath, queryParameters: {searchFlairParam: flair.flair}).toString(),
                          ),
                        ),
                      for (final user in users)
                        UserSuggestionTile(
                          user: user,
                          onTap: () => context.push(
                            Uri(path: searchResultsPath, queryParameters: {searchAuthorParam: user.id}).toString(),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
