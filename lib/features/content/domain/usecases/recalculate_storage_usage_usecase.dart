import 'package:bedbug/features/content/domain/entities/storage.dart';
import 'package:bedbug/features/content/domain/repositories/content_repository.dart';
import 'package:bedbug/features/content/domain/repositories/storage_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_storage_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/extensions/string_uuid_x.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [RecalculateStorageUsageUsecase].
final recalculateStorageUsageUsecaseProvider = Provider<RecalculateStorageUsageUsecase>(
  (ref) => RecalculateStorageUsageUsecase(ref.read(contentRepositoryProvider), ref.read(storageRepositoryProvider)),
);

/// Recalcule `Storage.currentSizeInBytes` en additionnant `sizeInBytes` de
/// tous les contenus stockés localement, puis persiste la valeur corrigée.
///
/// `currentSizeInBytes` est normalement maintenu de façon incrémentale par
/// les use cases qui ajoutent ou suppriment des contenus
/// (`SaveContentUsecase`, `SeedContentsUsecase`, `ClearContentsUsecase` via
/// `StorageRepository.adjustCurrentSizeInBytes`/`resetCurrentSizeInBytes`),
/// pour éviter de reparcourir l'intégralité des contenus à chaque écriture.
/// Mais un compteur incrémental peut dériver de
/// la réalité (crash entre l'ajout d'un contenu et la mise à jour du
/// compteur, chemin d'écriture qui l'aurait oublié, etc.) : ce use case sert
/// donc de réconciliation, à appeler ponctuellement (ex. au démarrage de
/// l'application) plutôt qu'à chaque lecture.
class RecalculateStorageUsageUsecase extends Usecase<NoParams, RecalculateStorageUsageFailure, int> {
  /// Crée un [RecalculateStorageUsageUsecase].
  RecalculateStorageUsageUsecase(this._contentRepository, this._storageRepository);

  final ContentRepository _contentRepository;
  final StorageRepository _storageRepository;

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
      return const Left(RecalculateStorageUsageFailure.unknown);
    }
  }
}

/// Échecs possibles du [RecalculateStorageUsageUsecase].
enum RecalculateStorageUsageFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors du recalcul du poids de stockage.
  unknown,
}
