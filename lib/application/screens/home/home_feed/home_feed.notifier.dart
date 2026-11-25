import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/application/notifiers/reaction_count_changes.notifier.dart';
import 'package:bedbug/core/domain/cursor_page.dart';
import 'package:bedbug/core/notifier/notifier_state.dart';
import 'package:bedbug/infra/resources/content/content/content.entity.detailed.dart';
import 'package:bedbug/logic/usecases/feed/get_home_feed/get_home_feed.failure.dart';
import 'package:bedbug/logic/usecases/feed/get_home_feed/get_home_feed.params.dart';
import 'package:bedbug/logic/usecases/feed/get_home_feed/get_home_feed.usecase.dart';
import 'package:bedbug/logic/usecases/feed/mark_content_viewed/mark_content_viewed.params.dart';
import 'package:bedbug/logic/usecases/feed/mark_content_viewed/mark_content_viewed.usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [HomeFeedNotifier].
final homeFeedNotifierProvider = AsyncNotifierProvider<HomeFeedNotifier, HomeFeedState>(HomeFeedNotifier.new);

/// Notifier récupérant le flux de contenus affiché sur la page d'accueil, page après page.
class HomeFeedNotifier extends AsyncNotifier<HomeFeedState> {
  /// Cas d'usage de récupération du flux de contenus de la home page.
  late final _getHomeFeedUsecase = ref.read(getHomeFeedUsecaseProvider);

  /// Cas d'usage de mémorisation d'un contenu vu.
  late final _markContentViewedUsecase = ref.read(markContentViewedUsecaseProvider);

  /// Nombre d'entrées du journal [reactionCountChangesNotifierProvider] déjà reflétées par la liste.
  int _appliedReactionChangeCount = 0;

  /// Charge la première page du fil, sur une session de lecture qui commence maintenant.
  ///
  /// Chaque rechargement ouvre une nouvelle session : les contenus reçus et vus depuis la précédente y prennent leur
  /// place. Les pages suivantes, chargées par [loadMore], restent sur la même session.
  @override
  Future<HomeFeedState> build() async {
    // La première page lue juste après inclut déjà les réactions enregistrées jusqu'ici.
    _appliedReactionChangeCount = ref.read(reactionCountChangesNotifierProvider).length;
    ref.listen(reactionCountChangesNotifierProvider, (_, changes) => _applyReactionCountChanges(changes));

    final feedStartedAt = DateTime.now();
    final result = await _getHomeFeedUsecase(GetHomeFeedParams(feedStartedAt: feedStartedAt));
    return result.fold(
      onFailure: (GetHomeFeedFailure failure) {
        return HomeFeedState(contents: const [], feedStartedAt: feedStartedAt, failureMessage: _messageFor(failure));
      },
      onSuccess: (CursorPage<ContentDetailed> page) {
        return HomeFeedState(
          contents: page.items,
          feedStartedAt: feedStartedAt,
          nextCursor: page.nextCursor,
          unviewedContentIds: _unviewedIdsOf(page.items),
        );
      },
    );
  }

  /// Recharge le flux et se termine une fois la nouvelle liste disponible.
  ///
  /// Les contenus reçus d'un pair arrivent directement en base, sans passer par ce notifier : c'est ainsi que
  /// l'utilisateur les fait apparaître. La liste actuelle reste affichée pendant le rechargement, qui ouvre une
  /// nouvelle session de lecture et repart de la première page.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Charge la page suivante du fil et l'ajoute à la suite des contenus affichés.
  ///
  /// Appelé quand l'utilisateur approche de la fin de la liste. Sans effet pendant un chargement, ou quand le fil est
  /// épuisé. Un échec garde la liste affichée telle quelle, avec un message et de quoi réessayer à sa fin.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || state.isLoading || current.isLoadingMore || current.nextCursor == null) {
      return;
    }
    state = AsyncData(
      HomeFeedState(
        contents: current.contents,
        feedStartedAt: current.feedStartedAt,
        nextCursor: current.nextCursor,
        unviewedContentIds: current.unviewedContentIds,
        isLoadingMore: true,
      ),
    );
    final result = await _getHomeFeedUsecase(
      GetHomeFeedParams(feedStartedAt: current.feedStartedAt, after: current.nextCursor),
    );
    final latest = state.value;
    // Un rechargement survenu entre-temps a ouvert une autre session : cette page n'en fait pas partie.
    if (!ref.mounted || latest == null || state.isLoading || latest.feedStartedAt != current.feedStartedAt) {
      return;
    }
    state = AsyncData(
      result.fold(
        onFailure: (GetHomeFeedFailure failure) {
          return HomeFeedState(
            contents: latest.contents,
            feedStartedAt: latest.feedStartedAt,
            nextCursor: latest.nextCursor,
            unviewedContentIds: latest.unviewedContentIds,
            loadMoreFailureMessage: _messageFor(failure),
          );
        },
        onSuccess: (CursorPage<ContentDetailed> page) {
          return HomeFeedState(
            contents: ContentDetailed.appendPage(latest.contents, page.items),
            feedStartedAt: latest.feedStartedAt,
            nextCursor: page.nextCursor,
            unviewedContentIds: {...latest.unviewedContentIds, ..._unviewedIdsOf(page.items)},
          );
        },
      ),
    );
  }

  /// Mémorise que l'utilisateur a vu le contenu [contentId].
  ///
  /// L'état ne change pas : la liste ne bouge pas sous les yeux de l'utilisateur, et le contenu garde son icône
  /// jusqu'au prochain rechargement. Un échec est sans gravité : le contenu sera simplement de nouveau signalé.
  ///
  /// - [contentId] : identifiant du contenu vu.
  Future<void> markViewed(String contentId) async {
    await _markContentViewedUsecase(MarkContentViewedParams(contentId: contentId));
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
      HomeFeedState(
        contents: ReactionCountChangesNotifier.apply(current.contents, pending),
        feedStartedAt: current.feedStartedAt,
        nextCursor: current.nextCursor,
        unviewedContentIds: current.unviewedContentIds,
        isLoadingMore: current.isLoadingMore,
        loadMoreFailureMessage: current.loadMoreFailureMessage,
        failureMessage: current.failureMessage,
      ),
    );
  }

  /// Retourne les identifiants des contenus de [items] à signaler comme nouveaux.
  ///
  /// Les contenus de l'utilisateur ne le sont jamais : il les connaît déjà.
  ///
  /// - [items] : contenus d'une page du fil.
  Set<String> _unviewedIdsOf(List<ContentDetailed> items) {
    return {
      for (final detailed in items)
        if (!detailed.content.isOwned && !detailed.isViewed) detailed.content.id,
    };
  }

  /// Retourne le message à afficher pour l'échec [failure].
  ///
  /// - [failure] : échec de lecture d'une page du fil.
  String _messageFor(GetHomeFeedFailure failure) {
    return switch (failure) {
      GetHomeFeedFailure.invalidData => ref.l10n.homeGetContentsInvalidData,
      GetHomeFeedFailure.storageError => ref.l10n.homeGetContentsStorageError,
      GetHomeFeedFailure.unknown => ref.l10n.homeGetContentsUnknown,
    };
  }
}

/// État du flux de contenus de la page d'accueil.
class HomeFeedState extends NotifierState {
  /// Crée un [HomeFeedState].
  ///
  /// - [contents] : contenus chargés jusqu'ici, toutes pages confondues.
  /// - [feedStartedAt] : début de la session de lecture, commun à toutes ses pages.
  /// - [nextCursor] : curseur de la page suivante, `null` quand le fil est épuisé.
  /// - [unviewedContentIds] : identifiants des contenus pas encore vus lors du chargement.
  /// - [isLoadingMore] : indique si une page suivante est en cours de chargement.
  /// - [loadMoreFailureMessage] : message d'erreur du dernier chargement d'une page suivante, `null` sans échec.
  /// - [failureMessage] : message d'erreur du chargement de la première page.
  HomeFeedState({
    required this.contents,
    required this.feedStartedAt,
    this.nextCursor,
    this.unviewedContentIds = const {},
    this.isLoadingMore = false,
    this.loadMoreFailureMessage,
    super.failureMessage,
  });

  /// Contenus chargés jusqu'ici, toutes pages confondues.
  final List<ContentDetailed> contents;

  /// Début de la session de lecture, commun à toutes ses pages.
  final DateTime feedStartedAt;

  /// Curseur de la page suivante, `null` quand le fil est épuisé.
  final String? nextCursor;

  /// Identifiants des contenus pas encore vus lors du chargement.
  final Set<String> unviewedContentIds;

  /// Indique si une page suivante est en cours de chargement.
  ///
  /// Exception assumée à l'absence de champ de chargement dans un état : `AsyncValue` couvre le chargement de la
  /// première page, ce champ celui d'une page suivante, pendant lequel la liste reste affichée.
  final bool isLoadingMore;

  /// Message d'erreur du dernier chargement d'une page suivante, `null` sans échec.
  final String? loadMoreFailureMessage;

  /// Indique s'il reste des contenus après ceux chargés.
  bool get hasMore {
    return nextCursor != null;
  }
}
