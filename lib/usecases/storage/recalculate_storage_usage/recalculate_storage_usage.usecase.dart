import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/extensions/string_uuid_x.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/content/content/content.repository.dart';
import 'package:bedbug/resources/content/content/content.repository.hive.dart';
import 'package:bedbug/resources/content/storage/storage.entity.dart';
import 'package:bedbug/resources/content/storage/storage.repository.dart';
import 'package:bedbug/resources/content/storage/storage.repository.hive.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.hive.dart';
import 'package:bedbug/usecases/storage/recalculate_storage_usage/recalculate_storage_usage.failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [RecalculateStorageUsageUsecase].
final recalculateStorageUsageUsecaseProvider = Provider<RecalculateStorageUsageUsecase>((ref) {
  return RecalculateStorageUsageUsecase(
    ref.read(contentRepositoryProvider),
    ref.read(storageRepositoryProvider),
    ref.read(errorLogRepositoryProvider),
  );
});

/// Recalcule `Storage.currentSizeInBytes` en additionnant `sizeInBytes` de
/// tous les contenus stockés localement, puis persiste la valeur corrigée.
///
/// `currentSizeInBytes` est normalement maintenu de façon incrémentale par
/// les use cases qui ajoutent ou suppriment des contenus
/// (`SaveContentUsecase`, `ClearContentsUsecase` via
/// `StorageRepository.adjustCurrentSizeInBytes`/`resetCurrentSizeInBytes`),
/// pour éviter de reparcourir l'intégralité des contenus à chaque écriture.
/// Mais un compteur incrémental peut dériver de
/// la réalité (crash entre l'ajout d'un contenu et la mise à jour du
/// compteur, chemin d'écriture qui l'aurait oublié, etc.) : ce use case sert
/// donc de réconciliation, à appeler ponctuellement (ex. au démarrage de
/// l'application) plutôt qu'à chaque lecture.
class RecalculateStorageUsageUsecase extends Usecase<NoParams, RecalculateStorageUsageFailure, int> {
  /// Crée un [RecalculateStorageUsageUsecase].
  RecalculateStorageUsageUsecase(this._contentRepository, this._storageRepository, this._errorLogRepository);

  final ContentRepository _contentRepository;
  final StorageRepository _storageRepository;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<RecalculateStorageUsageFailure, int>> call(NoParams params) async {
    try {
      final contents = await _contentRepository.getAll();
      final totalBytes = contents.fold<int>(0, (total, content) => total + content.sizeInBytes);

      final existing = await _storageRepository.getUnique('');
      if (existing != null) {
        await _storageRepository.updateOne(existing.copyWithCurrentSizeInBytes(totalBytes));
      } else {
        final now = DateTime.now();
        await _storageRepository.addOne(
          Storage(
            id: UuidX.generate(),
            createdAt: now,
            updatedAt: now,
            maxSizeInBytes: defaultMaxStorageSizeInBytes,
            currentSizeInBytes: totalBytes,
          ),
        );
      }

      return Right(totalBytes);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('RecalculateStorageUsageUsecase', error, stackTrace);
      return const Left(RecalculateStorageUsageFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('RecalculateStorageUsageUsecase', error, stackTrace);
      return const Left(RecalculateStorageUsageFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('RecalculateStorageUsageUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'RecalculateStorageUsageUsecase', error: error, stackTrace: stackTrace);
      return const Left(RecalculateStorageUsageFailure.unknown);
    }
  }
}
