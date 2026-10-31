import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/application/screens/home/home_feed_notifier.dart';
import 'package:bedbug/features/content/domain/entities/storage.dart';
import 'package:bedbug/features/content/domain/repositories/storage_repository.dart';
import 'package:bedbug/features/content/domain/usecases/enforce_storage_limit_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/get_storage_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/recalculate_survival_scores_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/save_storage_limit_usecase.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/notifier/notifier_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [StorageLimitNotifier].
final storageLimitNotifierProvider = AsyncNotifierProvider<StorageLimitNotifier, StorageLimitState>(
  StorageLimitNotifier.new,
);

/// Notifier de la limite de stockage réglée dans les paramètres.
class StorageLimitNotifier extends AsyncNotifier<StorageLimitState> {
  /// Cas d'usage de lecture de la configuration de stockage.
  late final _getStorageUsecase = ref.read(getStorageUsecaseProvider);

  /// Cas d'usage d'enregistrement de la limite.
  late final _saveStorageLimitUsecase = ref.read(saveStorageLimitUsecaseProvider);

  /// Cas d'usage de recalcul de la priorité de conservation.
  late final _recalculateSurvivalScoresUsecase = ref.read(recalculateSurvivalScoresUsecaseProvider);

  /// Cas d'usage de nettoyage du stockage.
  late final _enforceStorageLimitUsecase = ref.read(enforceStorageLimitUsecaseProvider);

  @override
  Future<StorageLimitState> build() async {
    final result = await _getStorageUsecase(const NoParams());
    return result.fold(
      onFailure: (GetStorageFailure failure) {
        final message = switch (failure) {
          GetStorageFailure.invalidData => ref.l10n.homeGetContentsInvalidData,
          GetStorageFailure.storageError => ref.l10n.homeGetContentsStorageError,
          GetStorageFailure.unknown => ref.l10n.homeGetContentsUnknown,
        };
        return StorageLimitState(limitInBytes: defaultMaxStorageSizeInBytes, failureMessage: message);
      },
      onSuccess: (Storage storage) => StorageLimitState(limitInBytes: storage.maxSizeInBytes),
    );
  }

  /// Enregistre [limitInBytes], puis l'applique tout de suite.
  ///
  /// Baisser la limite doit libérer l'espace sans attendre le prochain échange. Le fil d'accueil est rechargé si des
  /// contenus ont été supprimés, pour ne plus les afficher.
  ///
  /// - [limitInBytes] : nouvelle limite, en octets.
  Future<void> setLimit(int limitInBytes) async {
    final previous = state.requireValue.limitInBytes;
    state = AsyncData(StorageLimitState(limitInBytes: limitInBytes));

    final result = await _saveStorageLimitUsecase(SaveStorageLimitParams(maxSizeInBytes: limitInBytes));
    if (!result.isSuccess) {
      state = AsyncData(StorageLimitState(limitInBytes: previous, failureMessage: ref.l10n.settingsSaveError));
      return;
    }

    await _recalculateSurvivalScoresUsecase(const NoParams());
    final removedCount = (await _enforceStorageLimitUsecase(const NoParams())).right ?? 0;
    if (removedCount > 0) {
      ref.invalidate(homeFeedNotifierProvider);
    }
  }
}

/// État de la limite de stockage.
class StorageLimitState extends NotifierState {
  /// Crée un [StorageLimitState].
  ///
  /// - [limitInBytes] : limite actuelle, en octets.
  /// - [failureMessage] : message d'erreur éventuel (lecture ou enregistrement).
  StorageLimitState({required this.limitInBytes, super.failureMessage});

  /// Limite actuelle, en octets.
  final int limitInBytes;
}
