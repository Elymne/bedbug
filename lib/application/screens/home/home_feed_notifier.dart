import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/object_values/home_feed.dart';
import 'package:bedbug/features/content/domain/usecases/get_home_feed_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/mark_content_viewed_usecase.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/notifier/notifier_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [HomeFeedNotifier].
final homeFeedNotifierProvider = AsyncNotifierProvider<HomeFeedNotifier, HomeFeedState>(HomeFeedNotifier.new);

/// Notifier récupérant le flux de contenus affiché sur la page d'accueil.
class HomeFeedNotifier extends AsyncNotifier<HomeFeedState> {
  /// Cas d'usage de récupération du flux de contenus de la home page.
  late final _getHomeFeedUsecase = ref.read(getHomeFeedUsecaseProvider);

  /// Cas d'usage de mémorisation d'un contenu vu.
  late final _markContentViewedUsecase = ref.read(markContentViewedUsecaseProvider);

  @override
  Future<HomeFeedState> build() async {
    final result = await _getHomeFeedUsecase(const NoParams());
    return result.fold(
      onFailure: (GetHomeFeedFailure failure) {
        final message = switch (failure) {
          GetHomeFeedFailure.invalidData => ref.l10n.homeGetContentsInvalidData,
          GetHomeFeedFailure.storageError => ref.l10n.homeGetContentsStorageError,
          GetHomeFeedFailure.unknown => ref.l10n.homeGetContentsUnknown,
        };
        return HomeFeedState(contents: const [], failureMessage: message);
      },
      onSuccess: (HomeFeed feed) {
        return HomeFeedState(contents: feed.contents, unviewedContentIds: feed.unviewedContentIds);
      },
    );
  }

  /// Recharge le flux et se termine une fois la nouvelle liste disponible.
  ///
  /// Les contenus reçus d'un pair arrivent directement en base, sans passer par ce notifier : c'est ainsi que
  /// l'utilisateur les fait apparaître. La liste actuelle reste affichée pendant le rechargement.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
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
}

/// État du flux de contenus de la page d'accueil.
class HomeFeedState extends NotifierState {
  /// Crée un [HomeFeedState].
  ///
  /// - [contents] : liste des contenus chargés.
  /// - [unviewedContentIds] : identifiants des contenus pas encore vus lors du chargement.
  /// - [failureMessage] : message d'erreur éventuel.
  HomeFeedState({required this.contents, this.unviewedContentIds = const {}, super.failureMessage});

  /// Liste des contenus chargés.
  final List<Content> contents;

  /// Identifiants des contenus pas encore vus lors du chargement.
  final Set<String> unviewedContentIds;
}
