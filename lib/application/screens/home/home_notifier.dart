import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/usecases/get_contents_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/seed_contents_usecase.dart';
import 'package:bedbug/shared/notifier/notifier_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [HomeNotifier].
final homeNotifierProvider = AsyncNotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);

/// Notifier gérant l'état de la page d'accueil.
class HomeNotifier extends AsyncNotifier<HomeState> {
  /// Cas d'usage de récupération des contenus.
  late final _getContentsUsecase = ref.read(getContentsUsecaseProvider);

  /// Cas d'usage de génération de contenus factices.
  late final _seedContentsUsecase = ref.read(seedContentsUsecaseProvider);

  @override
  Future<HomeState> build() async {
    final result = await _getContentsUsecase(const GetContentsParams());
    return result.fold(
      onFailure: (GetContentsFailure failure) {
        final message = switch (failure) {
          GetContentsFailure.invalidData => ref.l10n.homeGetContentsInvalidData,
          GetContentsFailure.storageError => ref.l10n.homeGetContentsStorageError,
          GetContentsFailure.unknown => ref.l10n.homeGetContentsUnknown,
        };
        return HomeState(contents: const [], failureMessage: message);
      },
      onSuccess: (List<Content> contents) => HomeState(contents: contents),
    );
  }

  /// Génère des contenus factices puis recharge la liste.
  Future<void> seedAndReload() async {
    state = const AsyncLoading();
    await _seedContentsUsecase(const SeedContentsParams());
    ref.invalidateSelf();
  }
}

/// État de la page d'accueil.
class HomeState extends NotifierState {
  /// Crée un [HomeState].
  ///
  /// - [contents] : liste des contenus chargés.
  /// - [failureMessage] : message d'erreur éventuel.
  HomeState({required this.contents, super.failureMessage});

  /// Liste des contenus chargés.
  final List<Content> contents;
}
