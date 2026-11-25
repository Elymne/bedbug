import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/application/notifiers/reaction_count_changes.notifier.dart';
import 'package:bedbug/core/domain/cursor_page.dart';
import 'package:bedbug/core/notifier/notifier_state.dart';
import 'package:bedbug/infra/resources/content/content/content.entity.detailed.dart';
import 'package:bedbug/logic/usecases/feed/get_contents_by_flair/get_contents_by_flair.failure.dart';
import 'package:bedbug/logic/usecases/feed/get_contents_by_flair/get_contents_by_flair.params.dart';
import 'package:bedbug/logic/usecases/feed/get_contents_by_flair/get_contents_by_flair.usecase.dart';
import 'package:bedbug/logic/usecases/feed/get_contents_by_signatures/get_contents_by_signatures.failure.dart';
import 'package:bedbug/logic/usecases/feed/get_contents_by_signatures/get_contents_by_signatures.params.dart';
import 'package:bedbug/logic/usecases/feed/get_contents_by_signatures/get_contents_by_signatures.usecase.dart';
import 'package:bedbug/logic/usecases/feed/get_filtered_contents/get_filtered_contents.failure.dart';
import 'package:bedbug/logic/usecases/feed/get_filtered_contents/get_filtered_contents.params.dart';
import 'package:bedbug/logic/usecases/feed/get_filtered_contents/get_filtered_contents.usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SearchResultsNotifier], un par [SearchCriteria].
final searchResultsNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<SearchResultsNotifier, SearchResultsState, SearchCriteria>(SearchResultsNotifier.new);

/// Notifier chargeant les contenus correspondant à un [SearchCriteria], page après page.
class SearchResultsNotifier extends AsyncNotifier<SearchResultsState> {
  /// Crée un [SearchResultsNotifier].
  ///
  /// - [criteria] : critère de recherche dont on charge les résultats.
  SearchResultsNotifier(this.criteria);

  /// Critère de recherche dont on charge les résultats.
  final SearchCriteria criteria;

  /// Cas d'usage de récupération des contenus d'un flair.
  late final _getContentsByFlairUsecase = ref.read(getContentsByFlairUsecaseProvider);

  /// Cas d'usage de récupération des contenus de plusieurs auteurs.
  late final _getContentsBySignaturesUsecase = ref.read(getContentsBySignaturesUsecaseProvider);

  /// Cas d'usage de recherche globale sur le titre et le flair.
  late final _getFilteredContentsUsecase = ref.read(getFilteredContentsUsecaseProvider);

  /// Nombre d'entrées du journal [reactionCountChangesNotifierProvider] déjà reflétées par la liste.
  int _appliedReactionChangeCount = 0;

  /// Charge la première page des résultats.
  @override
  Future<SearchResultsState> build() async {
    // La première page lue juste après inclut déjà les réactions enregistrées jusqu'ici.
    _appliedReactionChangeCount = ref.read(reactionCountChangesNotifierProvider).length;
    ref.listen(reactionCountChangesNotifierProvider, (_, changes) => _applyReactionCountChanges(changes));

    final result = await _fetchPage(null);
    final page = result.page;
    if (page == null) {
      return SearchResultsState(contents: const [], failureMessage: result.failureMessage);
    }
    return SearchResultsState(contents: page.items, nextCursor: page.nextCursor);
  }

  /// Charge la page suivante des résultats et l'ajoute à la suite des contenus affichés.
  ///
  /// Appelé quand l'utilisateur approche de la fin de la liste. Sans effet pendant un chargement, ou quand les
  /// résultats sont épuisés. Un échec garde la liste affichée telle quelle, avec un message et de quoi réessayer à
  /// sa fin.
  Future<void> loadMore() async {
    final current = state.value;
    final after = current?.nextCursor;
    if (current == null || after == null || state.isLoading || current.isLoadingMore) {
      return;
    }
    state = AsyncData(SearchResultsState(contents: current.contents, nextCursor: after, isLoadingMore: true));
    final result = await _fetchPage(after);
    final latest = state.value;
    if (!ref.mounted || latest == null || state.isLoading) {
      return;
    }
    final page = result.page;
    if (page == null) {
      state = AsyncData(
        SearchResultsState(
          contents: latest.contents,
          nextCursor: latest.nextCursor,
          loadMoreFailureMessage: result.failureMessage,
        ),
      );
      return;
    }
    state = AsyncData(
      SearchResultsState(
        contents: ContentDetailed.appendPage(latest.contents, page.items),
        nextCursor: page.nextCursor,
      ),
    );
  }

  /// Reporte sur les contenus affichés les nombres de réactions du journal pas encore appliqués.
  ///
  /// - [changes] : journal complet des changements de nombre de réactions.
  void _applyReactionCountChanges(List<ReactionCountChange> changes) {
    final pending = changes.skip(_appliedReactionChangeCount);
    _appliedReactionChangeCount = changes.length;
    final current = state.value;
    // Pendant un chargement, la liste lue ensuite inclura déjà ces réactions.
    if (current == null || state.isLoading) {
      return;
    }
    state = AsyncData(
      SearchResultsState(
        contents: ReactionCountChangesNotifier.apply(current.contents, pending),
        nextCursor: current.nextCursor,
        isLoadingMore: current.isLoadingMore,
        loadMoreFailureMessage: current.loadMoreFailureMessage,
        failureMessage: current.failureMessage,
      ),
    );
  }

  /// Lit la page des résultats qui suit [after], selon le type de [criteria].
  ///
  /// Retourne la page lue, ou le message à afficher en cas d'échec.
  ///
  /// - [after] : curseur renvoyé par la page précédente, `null` pour la première page.
  Future<({CursorPage<ContentDetailed>? page, String? failureMessage})> _fetchPage(String? after) async {
    switch (criteria) {
      case FlairSearchCriteria(:final flair):
        final result = await _getContentsByFlairUsecase(GetContentsByFlairParams(flair: flair, after: after));
        return (
          page: result.right,
          failureMessage: switch (result.left) {
            null => null,
            GetContentsByFlairFailure.invalidData => ref.l10n.homeGetContentsInvalidData,
            GetContentsByFlairFailure.storageError => ref.l10n.homeGetContentsStorageError,
            GetContentsByFlairFailure.unknown => ref.l10n.homeGetContentsUnknown,
          },
        );
      case SignatureSearchCriteria(:final signatureId):
        final result = await _getContentsBySignaturesUsecase(
          GetContentsBySignaturesParams(signatureIds: [signatureId], after: after),
        );
        return (
          page: result.right,
          failureMessage: switch (result.left) {
            null => null,
            GetContentsBySignaturesFailure.invalidData => ref.l10n.homeGetContentsInvalidData,
            GetContentsBySignaturesFailure.storageError => ref.l10n.homeGetContentsStorageError,
            GetContentsBySignaturesFailure.unknown => ref.l10n.homeGetContentsUnknown,
          },
        );
      case QuerySearchCriteria(:final query):
        final result = await _getFilteredContentsUsecase(GetFilteredContentsParams(query: query, after: after));
        return (
          page: result.right,
          failureMessage: switch (result.left) {
            null => null,
            GetFilteredContentsFailure.invalidData => ref.l10n.homeGetContentsInvalidData,
            GetFilteredContentsFailure.storageError => ref.l10n.homeGetContentsStorageError,
            GetFilteredContentsFailure.unknown => ref.l10n.homeGetContentsUnknown,
          },
        );
    }
  }
}

/// État de la page de résultats de recherche.
class SearchResultsState extends NotifierState {
  /// Crée un [SearchResultsState].
  ///
  /// - [contents] : contenus correspondant au critère de recherche, chargés jusqu'ici, toutes pages confondues.
  /// - [nextCursor] : curseur de la page suivante, `null` quand les résultats sont épuisés.
  /// - [isLoadingMore] : indique si une page suivante est en cours de chargement.
  /// - [loadMoreFailureMessage] : message d'erreur du dernier chargement d'une page suivante, `null` sans échec.
  /// - [failureMessage] : message d'erreur du chargement de la première page.
  SearchResultsState({
    required this.contents,
    this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreFailureMessage,
    super.failureMessage,
  });

  /// Contenus correspondant au critère de recherche, chargés jusqu'ici, toutes pages confondues.
  final List<ContentDetailed> contents;

  /// Curseur de la page suivante, `null` quand les résultats sont épuisés.
  final String? nextCursor;

  /// Indique si une page suivante est en cours de chargement.
  ///
  /// Exception assumée à l'absence de champ de chargement dans un état : `AsyncValue` couvre le chargement de la
  /// première page, ce champ celui d'une page suivante, pendant lequel la liste reste affichée.
  final bool isLoadingMore;

  /// Message d'erreur du dernier chargement d'une page suivante, `null` sans échec.
  final String? loadMoreFailureMessage;

  /// Indique s'il reste des résultats après ceux chargés.
  bool get hasMore {
    return nextCursor != null;
  }
}

/// Critère de recherche des contenus à afficher.
///
/// Distingue les intentions de l'utilisateur : choisir un flair ou une
/// signature précise parmi les suggestions, ou valider sa saisie telle
/// quelle. Sert aussi d'argument au provider des résultats, d'où l'égalité
/// par valeur.
sealed class SearchCriteria {
  /// Constructeur constant pour permettre des sous-classes constantes.
  const SearchCriteria();
}

/// Recherche des contenus d'un flair choisi parmi les suggestions.
class FlairSearchCriteria extends SearchCriteria {
  /// Crée un [FlairSearchCriteria].
  ///
  /// - [flair] : flair choisi, sans le `/` initial.
  const FlairSearchCriteria(this.flair);

  /// Flair choisi, sans le `/` initial.
  final String flair;

  @override
  bool operator ==(Object other) {
    return other is FlairSearchCriteria && other.flair == flair;
  }

  @override
  int get hashCode {
    return Object.hash(FlairSearchCriteria, flair);
  }
}

/// Contenus d'une signature précise, désignée par son identifiant.
///
/// Sert la page de signature, ouverte par le choix d'une signature parmi les
/// suggestions.
class SignatureSearchCriteria extends SearchCriteria {
  /// Crée un [SignatureSearchCriteria].
  ///
  /// - [signatureId] : identifiant de la signature choisie.
  const SignatureSearchCriteria(this.signatureId);

  /// Identifiant de la signature choisie.
  final String signatureId;

  @override
  bool operator ==(Object other) {
    return other is SignatureSearchCriteria && other.signatureId == signatureId;
  }

  @override
  int get hashCode {
    return Object.hash(SignatureSearchCriteria, signatureId);
  }
}

/// Recherche globale sur le texte validé par l'utilisateur.
class QuerySearchCriteria extends SearchCriteria {
  /// Crée un [QuerySearchCriteria].
  ///
  /// - [query] : texte validé, comparé au titre et au flair des contenus.
  const QuerySearchCriteria(this.query);

  /// Texte validé, comparé au titre et au flair des contenus.
  final String query;

  @override
  bool operator ==(Object other) {
    return other is QuerySearchCriteria && other.query == query;
  }

  @override
  int get hashCode {
    return Object.hash(QuerySearchCriteria, query);
  }
}
