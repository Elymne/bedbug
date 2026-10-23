import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/usecases/get_home_feed_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/seed_contents_usecase.dart';
import 'package:bedbug/features/user/domain/entities/anonymous_user.dart';
import 'package:bedbug/features/user/domain/usecases/seed_users_usecase.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/notifier/notifier_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [HomeFeedNotifier].
final homeFeedNotifierProvider = AsyncNotifierProvider<HomeFeedNotifier, HomeFeedState>(HomeFeedNotifier.new);

/// Notifier récupérant le flux de contenus affiché sur la page d'accueil.
class HomeFeedNotifier extends AsyncNotifier<HomeFeedState> {
  /// Cas d'usage de récupération du flux de contenus de la home page.
  late final _getHomeFeedUsecase = ref.read(getHomeFeedUsecaseProvider);

  /// Cas d'usage de génération de contenus factices.
  late final _seedContentsUsecase = ref.read(seedContentsUsecaseProvider);

  /// Cas d'usage de génération d'utilisateurs factices, auteurs des contenus factices.
  late final _seedUsersUsecase = ref.read(seedUsersUsecaseProvider);

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
      onSuccess: (List<Content> contents) => HomeFeedState(contents: contents),
    );
  }

  /// Génère des utilisateurs et des contenus factices puis recharge la liste.
  ///
  /// Les contenus sont répartis au hasard entre les utilisateurs factices et
  /// l'anonyme. Si la génération des utilisateurs échoue, les contenus sont
  /// tout de même générés, avec des auteurs fictifs.
  Future<void> seedAndReload() async {
    state = const AsyncLoading();
    final seedUsersResult = await _seedUsersUsecase(const SeedUsersParams());
    final authorIds = [...?seedUsersResult.right, anonymousUserId];
    await _seedContentsUsecase(SeedContentsParams(authorIds: authorIds));
    ref.invalidateSelf();
  }
}

/// État du flux de contenus de la page d'accueil.
class HomeFeedState extends NotifierState {
  /// Crée un [HomeFeedState].
  ///
  /// - [contents] : liste des contenus chargés.
  /// - [failureMessage] : message d'erreur éventuel.
  HomeFeedState({required this.contents, super.failureMessage});

  /// Liste des contenus chargés.
  final List<Content> contents;
}
