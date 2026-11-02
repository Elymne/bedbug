import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/content/storage/storage.config.dart';
import 'package:bedbug/resources/content/storage/storage.repository.dart';
import 'package:bedbug/resources/content/storage/storage.repository.hive.dart';
import 'package:bedbug/resources/content/storage/storage.value_object.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.hive.dart';
import 'package:bedbug/usecases/storage/save_storage_limit/save_storage_limit.failure.dart';
import 'package:bedbug/usecases/storage/save_storage_limit/save_storage_limit.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SaveStorageLimitUsecase].
final saveStorageLimitUsecaseProvider = Provider<SaveStorageLimitUsecase>((ref) {
  return SaveStorageLimitUsecase(ref.read(storageRepositoryProvider), ref.read(errorLogRepositoryProvider));
});

/// Enregistre le poids maximal que les contenus peuvent occuper sur l'appareil.
///
/// L'espace disponible et le volume de contenus croisés varient d'un utilisateur à l'autre : la limite est donc son
/// choix. Elle reste bornée, car une limite trop basse viderait l'appareil de tout contenu reçu, et une limite trop
/// haute chargerait trop de contenus en mémoire.
class SaveStorageLimitUsecase extends Usecase<SaveStorageLimitParams, SaveStorageLimitFailure, Storage> {
  /// Crée un [SaveStorageLimitUsecase].
  SaveStorageLimitUsecase(this._storageRepository, this._errorLogRepository);

  final StorageRepository _storageRepository;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<SaveStorageLimitFailure, Storage>> call(SaveStorageLimitParams params) async {
    final isTooLow = params.maxSizeInBytes < minStorageLimitInMegabytes * bytesPerMegabyte;
    final isTooHigh = params.maxSizeInBytes > maxStorageLimitInMegabytes * bytesPerMegabyte;
    if (isTooLow || isTooHigh) {
      return const Left(SaveStorageLimitFailure.invalidLimit);
    }

    try {
      final storage = await _storageRepository.get() ?? defaultStorage;
      final updated = storage.copyWithMaxSizeInBytes(params.maxSizeInBytes);
      await _storageRepository.save(updated);
      return Right(updated);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('SaveStorageLimitUsecase', error, stackTrace);
      return const Left(SaveStorageLimitFailure.storageError);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('SaveStorageLimitUsecase', error, stackTrace);
      return const Left(SaveStorageLimitFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('SaveStorageLimitUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'SaveStorageLimitUsecase', error: error, stackTrace: stackTrace);
      return const Left(SaveStorageLimitFailure.unknown);
    }
  }
}
