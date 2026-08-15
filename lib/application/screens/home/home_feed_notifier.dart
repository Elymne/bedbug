import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/usecases/get_home_feed_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/seed_contents_usecase.dart';
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

  /// Génère des contenus factices puis recharge la liste.
  Future<void> seedAndReload() async {
    state = const AsyncLoading();
    await _seedContentsUsecase(const SeedContentsParams());
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
