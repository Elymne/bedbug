import 'package:bedbug/features/content/domain/repositories/content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [ClearContentsUsecase].
final clearContentsUsecaseProvider = Provider<ClearContentsUsecase>(
  (ref) => ClearContentsUsecase(ref.read(contentRepositoryProvider)),
);

/// Supprime l'intégralité des contenus stockés localement.
class ClearContentsUsecase
    extends Usecase<NoParams, ClearContentsFailure, void> {
  /// Crée un [ClearContentsUsecase].
  ClearContentsUsecase(this._contentRepository);

  final ContentRepository _contentRepository;

  @override
  Future<Either<ClearContentsFailure, void>> call(NoParams params) async {
    try {
      await _contentRepository.deleteAll();
      return const Right(null);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('ClearContentsUsecase', error, stackTrace);
      return const Left(ClearContentsFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('ClearContentsUsecase', error, stackTrace);
      return const Left(ClearContentsFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('ClearContentsUsecase', error, stackTrace);
      return const Left(ClearContentsFailure.unknown);
    }
  }
}

/// Échecs possibles du [ClearContentsUsecase].
enum ClearContentsFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la suppression des contenus.
  unknown,
}
