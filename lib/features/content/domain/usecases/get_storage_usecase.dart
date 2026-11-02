import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/extensions/string_uuid_x.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/content/storage.entity.dart';
import 'package:bedbug/resources/content/storage.repository.dart';
import 'package:bedbug/resources/content/storage.repository.hive.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetStorageUsecase].
final getStorageUsecaseProvider = Provider<GetStorageUsecase>((ref) {
  return GetStorageUsecase(ref.read(storageRepositoryProvider));
});

/// Récupère la configuration de stockage local.
///
/// Si aucune configuration n'existe encore, en crée une avec les valeurs
/// par défaut et la persiste avant de la retourner.
///
/// Journalise également un warning si plusieurs entrées sont trouvées dans
/// le stockage sous-jacent (`StorageRepository.countAll` > 1) : ce
/// repository gère un singleton et ne devrait jamais en contenir plus d'une.
/// Pour l'instant on se contente de loguer — si ce cas s'avère fréquent en
/// pratique, il faudra un vrai mécanisme de réparation (ex. fusionner ou
/// supprimer les entrées surnuméraires) plutôt qu'un simple log.
class GetStorageUsecase extends Usecase<NoParams, GetStorageFailure, Storage> {
  /// Crée un [GetStorageUsecase].
  GetStorageUsecase(this._storageRepository);

  final StorageRepository _storageRepository;

  @override
  Future<Either<GetStorageFailure, Storage>> call(NoParams params) async {
    try {
      final existing = await _storageRepository.getUnique('');

      final count = await _storageRepository.countAll();
      if (count > 1) {
        AppLogger.warning('GetStorageUsecase : $count entrées trouvées pour un stockage censé être unique.');
      }

      if (existing != null) {
        return Right(existing);
      }

      final now = DateTime.now();
      final defaults = Storage(
        id: UuidX.generate(),
        createdAt: now,
        updatedAt: now,
        maxSizeInBytes: defaultMaxStorageSizeInBytes,
      );
      await _storageRepository.addOne(defaults);
      return Right(defaults);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('GetStorageUsecase', error, stackTrace);
      return const Left(GetStorageFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('GetStorageUsecase', error, stackTrace);
      return const Left(GetStorageFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('GetStorageUsecase', error, stackTrace);
      return const Left(GetStorageFailure.unknown);
    }
  }
}

/// Échecs possibles du [GetStorageUsecase].
enum GetStorageFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue.
  unknown,
}
