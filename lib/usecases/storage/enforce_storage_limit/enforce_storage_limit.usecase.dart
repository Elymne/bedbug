import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/content/content/content.entity.dart';
import 'package:bedbug/resources/content/content/content.repository.dart';
import 'package:bedbug/resources/content/content/content.repository.hive.dart';
import 'package:bedbug/resources/content/storage/storage.config.dart';
import 'package:bedbug/resources/content/storage/storage.repository.dart';
import 'package:bedbug/resources/content/storage/storage.repository.hive.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.hive.dart';
import 'package:bedbug/services/content/delete_contents/delete_contents.failure.dart';
import 'package:bedbug/services/content/delete_contents/delete_contents.params.dart';
import 'package:bedbug/services/content/delete_contents/delete_contents.service.dart';
import 'package:bedbug/usecases/storage/enforce_storage_limit/enforce_storage_limit.failure.dart';
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

/// Ramène le poids des contenus sous la limite de stockage, et retourne le nombre de contenus supprimés.
///
/// Les échanges passifs ajoutent des contenus sans que l'utilisateur n'intervienne : sans ce nettoyage, ils
/// finiraient par remplir le téléphone. Les contenus reçus partent du plus faible `survivalScore` au plus fort, le
/// plus ancien d'abord à score égal. Les scores doivent donc être recalculés avant l'appel.
///
/// Les contenus de l'utilisateur ne sont jamais supprimés, même s'ils dépassent la limite à eux seuls : ce sont les
/// seuls qui n'existent peut-être nulle part ailleurs.
///
/// La suppression passe par [DeleteContentsService] : les contenus supprimés sont notamment mémorisés comme déjà vus,
/// sans quoi le prochain pair les renverrait aussitôt, pour un nouveau nettoyage. Le poids réel, recalculé ici,
/// corrige aussi un éventuel décalage du compteur de stockage.
class EnforceStorageLimitUsecase extends Usecase<NoParams, EnforceStorageLimitFailure, int> {
  /// Crée un [EnforceStorageLimitUsecase].
  EnforceStorageLimitUsecase(
    this._contentRepository,
    this._storageRepository,
    this._deleteContentsService,
    this._errorLogRepository,
  );

  final ContentRepository _contentRepository;
  final StorageRepository _storageRepository;
  final DeleteContentsService _deleteContentsService;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<EnforceStorageLimitFailure, int>> call(NoParams params) async {
    try {
      final storage = await _storageRepository.get();
      final limit = storage?.maxSizeInBytes ?? defaultMaxStorageSizeInBytes;
      final contents = await _contentRepository.getAll();

      var totalBytes = contents.fold<int>(0, (total, content) => total + content.sizeInBytes);
      final removed = <Content>[];
      if (totalBytes > limit) {
        final candidates = contents.where((content) => !content.isOwned).toList()..sort(_compareSurvival);
        for (final content in candidates) {
          if (totalBytes <= limit) {
            break;
          }
          removed.add(content);
          totalBytes -= content.sizeInBytes;
        }
      }

      final deletion = await _deleteContentsService(DeleteContentsParams(contents: removed));
      final failure = deletion.left;
      if (failure != null) {
        return Left(switch (failure) {
          DeleteContentsFailure.storageError => EnforceStorageLimitFailure.storageError,
          DeleteContentsFailure.unknown => EnforceStorageLimitFailure.unknown,
        });
      }

      // Le service a déjà retiré le poids des contenus supprimés du compteur : il ne reste qu'à corriger un éventuel
      // décalage entre ce compteur, relu après la suppression, et le poids réel des contenus restants.
      final storageAfterDeletion = await _storageRepository.get();
      final drift = totalBytes - (storageAfterDeletion?.currentSizeInBytes ?? 0);
      if (drift != 0) {
        await _storageRepository.adjustCurrentSizeInBytes(drift);
      }

      return Right(removed.length);
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

  /// Classe [first] et [second] dans l'ordre de suppression.
  ///
  /// - [first] : premier contenu comparé.
  /// - [second] : second contenu comparé.
  int _compareSurvival(Content first, Content second) {
    final byScore = first.survivalScore.compareTo(second.survivalScore);
    return byScore != 0 ? byScore : first.createdAt.compareTo(second.createdAt);
  }
}
