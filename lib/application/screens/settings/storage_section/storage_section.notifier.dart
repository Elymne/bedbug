import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/application/screens/home/home_feed/home_feed.notifier.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/core/notifier/notifier_state.dart';
import 'package:bedbug/resources/content/storage/storage.config.dart';
import 'package:bedbug/resources/content/storage/storage.value_object.dart';
import 'package:bedbug/usecases/storage/enforce_storage_limit/enforce_storage_limit.usecase.dart';
import 'package:bedbug/usecases/storage/get_storage/get_storage.failure.dart';
import 'package:bedbug/usecases/storage/get_storage/get_storage.usecase.dart';
import 'package:bedbug/usecases/storage/recalculate_survival_scores/recalculate_survival_scores.usecase.dart';
import 'package:bedbug/usecases/storage/save_storage_limit/save_storage_limit.params.dart';
import 'package:bedbug/usecases/storage/save_storage_limit/save_storage_limit.usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [StorageSectionNotifier].
final storageSectionNotifierProvider = AsyncNotifierProvider<StorageSectionNotifier, StorageSectionState>(
  StorageSectionNotifier.new,
);

/// Notifier de la limite de stockage réglée dans les paramètres.
class StorageSectionNotifier extends AsyncNotifier<StorageSectionState> {
  /// Cas d'usage de lecture de la configuration de stockage.
  late final _getStorageUsecase = ref.read(getStorageUsecaseProvider);

  /// Cas d'usage d'enregistrement de la limite.
  late final _saveStorageLimitUsecase = ref.read(saveStorageLimitUsecaseProvider);

  /// Cas d'usage de recalcul de la priorité de conservation.
  late final _recalculateSurvivalScoresUsecase = ref.read(recalculateSurvivalScoresUsecaseProvider);

  /// Cas d'usage de nettoyage du stockage.
  late final _enforceStorageLimitUsecase = ref.read(enforceStorageLimitUsecaseProvider);

  @override
  Future<StorageSectionState> build() async {
    final result = await _getStorageUsecase(const NoParams());
    return result.fold(
      onFailure: (GetStorageFailure failure) {
        final message = switch (failure) {
          GetStorageFailure.invalidData => ref.l10n.homeGetContentsInvalidData,
          GetStorageFailure.storageError => ref.l10n.homeGetContentsStorageError,
          GetStorageFailure.unknown => ref.l10n.homeGetContentsUnknown,
        };
        return StorageSectionState(limitInBytes: defaultMaxStorageSizeInBytes, failureMessage: message);
      },
      onSuccess: (Storage storage) => StorageSectionState(limitInBytes: storage.maxSizeInBytes),
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
    state = AsyncData(StorageSectionState(limitInBytes: limitInBytes));

    final result = await _saveStorageLimitUsecase(SaveStorageLimitParams(maxSizeInBytes: limitInBytes));
    if (!result.isSuccess) {
      state = AsyncData(StorageSectionState(limitInBytes: previous, failureMessage: ref.l10n.settingsSaveError));
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
class StorageSectionState extends NotifierState {
  /// Crée un [StorageSectionState].
  ///
  /// - [limitInBytes] : limite actuelle, en octets.
  /// - [failureMessage] : message d'erreur éventuel (lecture ou enregistrement).
  StorageSectionState({required this.limitInBytes, super.failureMessage});

  /// Limite actuelle, en octets.
  final int limitInBytes;
}
