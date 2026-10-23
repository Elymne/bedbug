import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/application/screens/search_results/search_criteria.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/usecases/get_contents_by_flair_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/get_filtered_contents_usecase.dart';
import 'package:bedbug/shared/notifier/notifier_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SearchResultsNotifier], un par [SearchCriteria].
final searchResultsNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<SearchResultsNotifier, SearchResultsState, SearchCriteria>(SearchResultsNotifier.new);

/// Notifier chargeant les contenus correspondant à un [SearchCriteria].
class SearchResultsNotifier extends AsyncNotifier<SearchResultsState> {
  /// Crée un [SearchResultsNotifier].
  ///
  /// - [criteria] : critère de recherche dont on charge les résultats.
  SearchResultsNotifier(this.criteria);

  /// Critère de recherche dont on charge les résultats.
  final SearchCriteria criteria;

  /// Cas d'usage de récupération des contenus d'un flair.
  late final _getContentsByFlairUsecase = ref.read(getContentsByFlairUsecaseProvider);

  /// Cas d'usage de recherche globale sur le titre et le flair.
  late final _getFilteredContentsUsecase = ref.read(getFilteredContentsUsecaseProvider);

  @override
  Future<SearchResultsState> build() async {
    return switch (criteria) {
      FlairSearchCriteria(:final flair) => _loadByFlair(flair),
      QuerySearchCriteria(:final query) => _loadByQuery(query),
    };
  }

  /// Charge les contenus rattachés exactement à [flair].
  Future<SearchResultsState> _loadByFlair(String flair) async {
    final result = await _getContentsByFlairUsecase(GetContentsByFlairParams(flair: flair));
    return result.fold(
      onFailure: (GetContentsByFlairFailure failure) {
        final message = switch (failure) {
          GetContentsByFlairFailure.invalidData => ref.l10n.homeGetContentsInvalidData,
          GetContentsByFlairFailure.storageError => ref.l10n.homeGetContentsStorageError,
          GetContentsByFlairFailure.unknown => ref.l10n.homeGetContentsUnknown,
        };
        return SearchResultsState(contents: const [], failureMessage: message);
      },
      onSuccess: (List<Content> contents) => SearchResultsState(contents: contents),
    );
  }

  /// Charge les contenus dont le titre ou le flair contient [query].
  Future<SearchResultsState> _loadByQuery(String query) async {
    final result = await _getFilteredContentsUsecase(GetFilteredContentsParams(query: query));
    return result.fold(
      onFailure: (GetFilteredContentsFailure failure) {
        final message = switch (failure) {
          GetFilteredContentsFailure.invalidData => ref.l10n.homeGetContentsInvalidData,
          GetFilteredContentsFailure.storageError => ref.l10n.homeGetContentsStorageError,
          GetFilteredContentsFailure.unknown => ref.l10n.homeGetContentsUnknown,
        };
        return SearchResultsState(contents: const [], failureMessage: message);
      },
      onSuccess: (List<Content> contents) => SearchResultsState(contents: contents),
    );
  }
}

/// État de la page de résultats de recherche.
class SearchResultsState extends NotifierState {
  /// Crée un [SearchResultsState].
  ///
  /// - [contents] : contenus correspondant au critère de recherche.
  /// - [failureMessage] : message d'erreur éventuel.
  SearchResultsState({required this.contents, super.failureMessage});

  /// Contenus correspondant au critère de recherche.
  final List<Content> contents;
}
