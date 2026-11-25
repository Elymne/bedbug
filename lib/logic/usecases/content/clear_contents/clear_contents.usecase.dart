import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.drift.dart';
import 'package:bedbug/infra/resources/content/storage/storage.repository.dart';
import 'package:bedbug/infra/resources/content/storage/storage.repository.drift.dart';
import 'package:bedbug/infra/resources/data.exception.dart';
import 'package:bedbug/infra/resources/datasource.exception.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.drift.dart';
import 'package:bedbug/logic/usecases/content/clear_contents/clear_contents.failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [ClearContentsUsecase].
final clearContentsUsecaseProvider = Provider<ClearContentsUsecase>((ref) {
  return ClearContentsUsecase(
    ref.read(contentRepositoryProvider),
    ref.read(storageRepositoryProvider),
    ref.read(errorLogRepositoryProvider),
  );
});

/// Supprime l'intégralité des contenus stockés localement, ainsi que leurs réactions et commentaires.
///
/// Sert à repartir d'un téléphone vide. Les réactions, commentaires et traces d'affichage partent avec leurs contenus ;
/// la place libérée est ensuite rendue au système, sans quoi le fichier garderait sa taille d'avant le vidage.
class ClearContentsUsecase extends Usecase<NoParams, ClearContentsFailure, void> {
  /// Crée un [ClearContentsUsecase].
  ClearContentsUsecase(this._contentRepository, this._storageRepository, this._errorLogRepository);

  /// Repository des contenus.
  final ContentRepository _contentRepository;

  /// Repository du stockage, qui rend la place libérée.
  final StorageRepository _storageRepository;

  /// Journal des erreurs inattendues.
  final ErrorLogRepository _errorLogRepository;

  /// Exécute l'opération décrite par la classe ; les échecs prévus sont retournés en [Left], jamais levés.
  @override
  Future<Either<ClearContentsFailure, void>> call(NoParams params) async {
    try {
      await _contentRepository.deleteAll();
      await _storageRepository.releaseFreePages();
      return const Right(null);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('ClearContentsUsecase', error, stackTrace);
      return const Left(ClearContentsFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('ClearContentsUsecase', error, stackTrace);
      return const Left(ClearContentsFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('ClearContentsUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'ClearContentsUsecase', error: error, stackTrace: stackTrace);
      return const Left(ClearContentsFailure.unknown);
    }
  }
}
