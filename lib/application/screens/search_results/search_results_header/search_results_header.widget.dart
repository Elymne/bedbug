import 'package:bedbug/application/notifiers/content_author.notifier.dart';
import 'package:bedbug/application/notifiers/search_results.notifier.dart';
import 'package:bedbug/application/widgets/headers/app_page_header.widget.dart';
import 'package:bedbug/core/extensions/build_context_x.dart';
import 'package:bedbug/resources/content/content/content.config.dart';
import 'package:bedbug/resources/signature/signature/signature.config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// En-tête de la page de résultats : retour, et titre décrivant la recherche.
///
/// Le titre reprend le flair (`f/flair`), la saisie, ou le pseudo de la signature (`s/pseudo`). Seul ce dernier cas
/// observe un état, le profil de la signature : le temps de le charger, le titre se contente du préfixe.
class SearchResultsHeader extends ConsumerWidget {
  /// Crée un [SearchResultsHeader].
  ///
  /// - [criteria] : critère de recherche décrit par le titre.
  const SearchResultsHeader({super.key, required this.criteria});

  /// Critère de recherche décrit par le titre.
  final SearchCriteria criteria;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = switch (criteria) {
      FlairSearchCriteria(:final flair) => flair,
      SignatureSearchCriteria(:final signatureId) =>
        ref.watch(contentAuthorNotifierProvider(signatureId)).value?.pseudo ?? '',
      QuerySearchCriteria(:final query) => context.loc.searchResultsQueryTitle(query),
    };
    final titlePrefix = switch (criteria) {
      FlairSearchCriteria() => flairPrefix,
      SignatureSearchCriteria() => signaturePrefix,
      QuerySearchCriteria() => null,
    };

    return AppPageHeader(title: title, titlePrefix: titlePrefix, onBack: context.pop);
  }
}
