import 'package:bedbug/features/content/domain/entities/storage.dart';
import 'package:bedbug/features/content/domain/repositories/storage_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_storage_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/extensions/string_uuid_x.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SaveStorageLimitUsecase].
final saveStorageLimitUsecaseProvider = Provider<SaveStorageLimitUsecase>((ref) {
  return SaveStorageLimitUsecase(ref.read(storageRepositoryProvider));
});

/// Enregistre le poids maximal que les contenus peuvent occuper sur l'appareil.
///
/// L'espace disponible et le volume de contenus croisés varient d'un utilisateur à l'autre : la limite est donc son
/// choix. Elle reste bornée, car une limite trop basse viderait l'appareil de tout contenu reçu, et une limite trop
/// haute chargerait trop de contenus en mémoire.
class SaveStorageLimitUsecase extends Usecase<SaveStorageLimitParams, SaveStorageLimitFailure, Storage> {
  /// Crée un [SaveStorageLimitUsecase].
  SaveStorageLimitUsecase(this._storageRepository);

  final StorageRepository _storageRepository;

  @override
  Future<Either<SaveStorageLimitFailure, Storage>> call(SaveStorageLimitParams params) async {
    final isTooLow = params.maxSizeInBytes < minStorageLimitInMegabytes * bytesPerMegabyte;
    final isTooHigh = params.maxSizeInBytes > maxStorageLimitInMegabytes * bytesPerMegabyte;
    if (isTooLow || isTooHigh) {
      return const Left(SaveStorageLimitFailure.invalidLimit);
    }

    try {
      final existing = await _storageRepository.getUnique('');
      if (existing != null) {
        return Right(await _storageRepository.updateOne(existing.copyWithMaxSizeInBytes(params.maxSizeInBytes)));
      }

      final now = DateTime.now();
      final created = Storage(
        id: UuidX.generate(),
        createdAt: now,
        updatedAt: now,
        maxSizeInBytes: params.maxSizeInBytes,
      );
      return Right(await _storageRepository.addOne(created));
    } on DataException catch (error, stackTrace) {
      AppLogger.error('SaveStorageLimitUsecase', error, stackTrace);
      return const Left(SaveStorageLimitFailure.storageError);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('SaveStorageLimitUsecase', error, stackTrace);
      return const Left(SaveStorageLimitFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('SaveStorageLimitUsecase', error, stackTrace);
      return const Left(SaveStorageLimitFailure.unknown);
    }
  }
}

/// Échecs possibles du [SaveStorageLimitUsecase].
enum SaveStorageLimitFailure {
  /// La limite demandée sort des bornes autorisées.
  invalidLimit,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de l'enregistrement.
  unknown,
}

/// Paramètres du [SaveStorageLimitUsecase].
class SaveStorageLimitParams extends Params {
  /// Crée des [SaveStorageLimitParams].
  ///
  /// - [maxSizeInBytes] : nouvelle limite, en octets.
  const SaveStorageLimitParams({required this.maxSizeInBytes});

  /// Nouvelle limite, en octets.
  final int maxSizeInBytes;
}
