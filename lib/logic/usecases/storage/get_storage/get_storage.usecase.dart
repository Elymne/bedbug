import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/infra/resources/content/storage/storage.config.dart';
import 'package:bedbug/infra/resources/content/storage/storage.repository.dart';
import 'package:bedbug/infra/resources/content/storage/storage.repository.drift.dart';
import 'package:bedbug/infra/resources/content/storage/storage.value_object.dart';
import 'package:bedbug/infra/resources/data.exception.dart';
import 'package:bedbug/infra/resources/datasource.exception.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.drift.dart';
import 'package:bedbug/logic/usecases/storage/get_storage/get_storage.failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetStorageUsecase].
final getStorageUsecaseProvider = Provider<GetStorageUsecase>((ref) {
  return GetStorageUsecase(ref.read(storageRepositoryProvider), ref.read(errorLogRepositoryProvider));
});

/// Récupère la configuration de stockage local.
///
/// Si aucune configuration n'existe encore, en crée une avec les valeurs
/// par défaut et la persiste avant de la retourner.
class GetStorageUsecase extends Usecase<NoParams, GetStorageFailure, Storage> {
  /// Crée un [GetStorageUsecase].
  GetStorageUsecase(this._storageRepository, this._errorLogRepository);

  final StorageRepository _storageRepository;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<GetStorageFailure, Storage>> call(NoParams params) async {
    try {
      final existing = await _storageRepository.get();

      if (existing != null) {
        return Right(existing);
      }

      await _storageRepository.save(defaultStorage);
      return const Right(defaultStorage);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('GetStorageUsecase', error, stackTrace);
      return const Left(GetStorageFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('GetStorageUsecase', error, stackTrace);
      return const Left(GetStorageFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('GetStorageUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'GetStorageUsecase', error: error, stackTrace: stackTrace);
      return const Left(GetStorageFailure.unknown);
    }
  }
}
