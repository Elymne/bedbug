import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/usecases/get_contents_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/seed_contents_usecase.dart';
import 'package:bedbug/shared/notifier/notifier_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Distance maximale (en pixels) sur laquelle la searchbar et la navbar peuvent sortir de l'écran.
///
/// Supérieure à la hauteur des deux barres : chacune se clampe indépendamment
/// à sa propre hauteur lors de l'affichage.
const double _maxBarsHiddenOffset = 200;

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

  /// Fait avancer la sortie d'écran de la searchbar et de la navbar de [delta] pixels.
  ///
  /// - [delta] : distance de scroll depuis la dernière position. Positif
  ///   (scroll vers le bas) fait sortir les barres, négatif (scroll vers
  ///   le haut) les fait revenir.
  void applyScrollDelta(double delta) {
    final currentState = state.value;
    if (currentState == null) return;
    final updatedOffset = (currentState.barsHiddenOffset + delta).clamp(0.0, _maxBarsHiddenOffset);
    if (updatedOffset == currentState.barsHiddenOffset) return;
    state = AsyncData(currentState.copyWith(barsHiddenOffset: updatedOffset));
  }
}

/// État de la page d'accueil.
class HomeState extends NotifierState {
  /// Crée un [HomeState].
  ///
  /// - [contents] : liste des contenus chargés.
  /// - [barsHiddenOffset] : distance (en pixels) sur laquelle la searchbar et la navbar sont sorties de l'écran.
  /// - [failureMessage] : message d'erreur éventuel.
  HomeState({required this.contents, this.barsHiddenOffset = 0, super.failureMessage});

  /// Liste des contenus chargés.
  final List<Content> contents;

  /// Distance (en pixels) sur laquelle la searchbar et la navbar sont sorties de l'écran.
  final double barsHiddenOffset;

  /// Retourne une copie de cet état avec [barsHiddenOffset] remplacé si fourni.
  HomeState copyWith({double? barsHiddenOffset}) {
    return HomeState(
      contents: contents,
      barsHiddenOffset: barsHiddenOffset ?? this.barsHiddenOffset,
      failureMessage: failureMessage,
    );
  }
}
