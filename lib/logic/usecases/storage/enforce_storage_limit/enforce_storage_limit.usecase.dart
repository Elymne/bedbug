import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.drift.dart';
import 'package:bedbug/infra/resources/content/storage/storage.config.dart';
import 'package:bedbug/infra/resources/content/storage/storage.repository.dart';
import 'package:bedbug/infra/resources/content/storage/storage.repository.drift.dart';
import 'package:bedbug/infra/resources/data.exception.dart';
import 'package:bedbug/infra/resources/datasource.exception.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.drift.dart';
import 'package:bedbug/logic/services/content/delete_contents/delete_contents.failure.dart';
import 'package:bedbug/logic/services/content/delete_contents/delete_contents.params.dart';
import 'package:bedbug/logic/services/content/delete_contents/delete_contents.service.dart';
import 'package:bedbug/logic/usecases/storage/enforce_storage_limit/enforce_storage_limit.config.dart';
import 'package:bedbug/logic/usecases/storage/enforce_storage_limit/enforce_storage_limit.failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [EnforceStorageLimitUsecase].
final enforceStorageLimitUsecaseProvider = Provider<EnforceStorageLimitUsecase>((ref) {
  return EnforceStorageLimitUsecase(
    ref.read(contentRepositoryProvider),
    ref.read(storageRepositoryProvider),
    ref.read(deleteContentsServiceProvider),
    ref.read(errorLogRepositoryProvider),
  );
});

/// Ramène le poids réel des données sous la limite de stockage, et retourne le nombre de contenus supprimés.
///
/// Les échanges passifs ajoutent des contenus sans que l'utilisateur n'intervienne : sans ce nettoyage, ils
/// finiraient par remplir le téléphone. Les contenus reçus partent du plus faible `survivalScore` au plus fort, le
/// plus ancien d'abord à score égal. Les scores doivent donc être recalculés avant l'appel.
///
/// Le poids comparé à la limite est celui de la base elle-même, mesuré et non tenu à jour à la main : il compte aussi
/// les réactions, signatures et index. Le poids de chaque contenu ne sert qu'à estimer combien en supprimer avant de
/// remesurer ; le nettoyage se fait donc par tours, jusqu'à repasser sous la limite ou n'avoir plus rien à supprimer.
///
/// Les contenus de l'utilisateur ne sont jamais supprimés, même s'ils dépassent la limite à eux seuls : ce sont les
/// seuls qui n'existent peut-être nulle part ailleurs.
///
/// La suppression passe par [DeleteContentsService] : les contenus supprimés sont notamment mémorisés comme déjà vus,
/// sans quoi le prochain pair les renverrait aussitôt, pour un nouveau nettoyage.
class EnforceStorageLimitUsecase extends Usecase<NoParams, EnforceStorageLimitFailure, int> {
  /// Crée un [EnforceStorageLimitUsecase].
  EnforceStorageLimitUsecase(
    this._contentRepository,
    this._storageRepository,
    this._deleteContentsService,
    this._errorLogRepository,
  );

  /// Repository des contenus, qui fournit les candidats à la suppression.
  final ContentRepository _contentRepository;

  /// Repository du stockage : limite et poids réel.
  final StorageRepository _storageRepository;

  /// Service de suppression des contenus.
  final DeleteContentsService _deleteContentsService;

  /// Journal des erreurs inattendues.
  final ErrorLogRepository _errorLogRepository;

  /// Exécute l'opération décrite par la classe ; les échecs prévus sont retournés en [Left], jamais levés.
  @override
  Future<Either<EnforceStorageLimitFailure, int>> call(NoParams params) async {
    try {
      final storage = await _storageRepository.get();
      final limit = storage?.maxSizeInBytes ?? defaultMaxStorageSizeInBytes;

      var removedCount = 0;
      var usedBytes = await _storageRepository.getUsedSizeInBytes();
      for (var round = 0; round < maxStorageCleanupRounds && usedBytes > limit; round++) {
        final candidates = await _contentRepository.getReceivedSummariesBySurvival(storageCleanupBatchSize);
        if (candidates.isEmpty) {
          break;
        }

        final excessBytes = usedBytes - limit;
        final removedIds = <String>[];
        var estimatedFreedBytes = 0;
        for (final candidate in candidates) {
          if (estimatedFreedBytes >= excessBytes) {
            break;
          }
          removedIds.add(candidate.contentId);
          estimatedFreedBytes += candidate.sizeInBytes;
        }

        final failure = (await _deleteContentsService(DeleteContentsParams(contentIds: removedIds))).left;
        if (failure != null) {
          return Left(switch (failure) {
            DeleteContentsFailure.storageError => EnforceStorageLimitFailure.storageError,
            DeleteContentsFailure.unknown => EnforceStorageLimitFailure.unknown,
          });
        }
        removedCount += removedIds.length;
        await _storageRepository.releaseFreePages();
        usedBytes = await _storageRepository.getUsedSizeInBytes();
      }

      return Right(removedCount);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('EnforceStorageLimitUsecase', error, stackTrace);
      return const Left(EnforceStorageLimitFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('EnforceStorageLimitUsecase', error, stackTrace);
      return const Left(EnforceStorageLimitFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('EnforceStorageLimitUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'EnforceStorageLimitUsecase', error: error, stackTrace: stackTrace);
      return const Left(EnforceStorageLimitFailure.unknown);
    }
  }
}
