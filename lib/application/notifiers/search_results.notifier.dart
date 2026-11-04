import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/core/notifier/notifier_state.dart';
import 'package:bedbug/resources/content/content/content.entity.dart';
import 'package:bedbug/usecases/feed/get_contents_by_flair/get_contents_by_flair.failure.dart';
import 'package:bedbug/usecases/feed/get_contents_by_flair/get_contents_by_flair.params.dart';
import 'package:bedbug/usecases/feed/get_contents_by_flair/get_contents_by_flair.usecase.dart';
import 'package:bedbug/usecases/feed/get_contents_by_signatures/get_contents_by_signatures.failure.dart';
import 'package:bedbug/usecases/feed/get_contents_by_signatures/get_contents_by_signatures.params.dart';
import 'package:bedbug/usecases/feed/get_contents_by_signatures/get_contents_by_signatures.usecase.dart';
import 'package:bedbug/usecases/feed/get_filtered_contents/get_filtered_contents.failure.dart';
import 'package:bedbug/usecases/feed/get_filtered_contents/get_filtered_contents.params.dart';
import 'package:bedbug/usecases/feed/get_filtered_contents/get_filtered_contents.usecase.dart';
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

  /// Cas d'usage de récupération des contenus de plusieurs auteurs.
  late final _getContentsBySignaturesUsecase = ref.read(getContentsBySignaturesUsecaseProvider);

  /// Cas d'usage de recherche globale sur le titre et le flair.
  late final _getFilteredContentsUsecase = ref.read(getFilteredContentsUsecaseProvider);

  @override
  Future<SearchResultsState> build() async {
    return switch (criteria) {
      FlairSearchCriteria(:final flair) => _loadByFlair(flair),
      SignatureSearchCriteria(:final signatureId) => _loadBySignatures([signatureId]),
      QuerySearchCriteria(:final query) => _loadByQuery(query),
    };
  }

  /// Charge les contenus signés par l'un des [signatureIds].
  Future<SearchResultsState> _loadBySignatures(List<String> signatureIds) async {
    final result = await _getContentsBySignaturesUsecase(GetContentsBySignaturesParams(signatureIds: signatureIds));
    return result.fold(
      onFailure: (GetContentsBySignaturesFailure failure) {
        final message = switch (failure) {
          GetContentsBySignaturesFailure.invalidData => ref.l10n.homeGetContentsInvalidData,
          GetContentsBySignaturesFailure.storageError => ref.l10n.homeGetContentsStorageError,
          GetContentsBySignaturesFailure.unknown => ref.l10n.homeGetContentsUnknown,
        };
        return SearchResultsState(contents: const [], failureMessage: message);
      },
      onSuccess: (List<Content> contents) => SearchResultsState(contents: contents),
    );
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
