import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/content/content/content.repository.dart';
import 'package:bedbug/resources/content/content/content.repository.hive.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.hive.dart';
import 'package:bedbug/services/content/delete_contents/delete_contents.failure.dart';
import 'package:bedbug/services/content/delete_contents/delete_contents.params.dart';
import 'package:bedbug/services/content/delete_contents/delete_contents.service.dart';
import 'package:bedbug/usecases/content/delete_own_content/delete_own_content.failure.dart';
import 'package:bedbug/usecases/content/delete_own_content/delete_own_content.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [DeleteOwnContentUsecase].
final deleteOwnContentUsecaseProvider = Provider<DeleteOwnContentUsecase>((ref) {
  return DeleteOwnContentUsecase(
    ref.read(contentRepositoryProvider),
    ref.read(deleteContentsServiceProvider),
    ref.read(errorLogRepositoryProvider),
  );
});

/// Supprime de l'appareil un contenu que son utilisateur a lui-même publié.
///
/// Permet de retirer un post regretté avant qu'il ne se propage. Seuls les
/// contenus créés sur cet appareil (`isOwned`) peuvent être supprimés ainsi :
/// un contenu reçu d'un pair n'appartient pas à l'utilisateur, il disparaîtra
/// selon les règles de nettoyage du stockage. La suppression est locale : les
/// copies déjà transmises à d'autres appareils ne peuvent pas être rappelées.
///
/// La suppression passe par [DeleteContentsService] : réactions, commentaires et poids partent avec le contenu, et
/// il est mémorisé comme déjà vu, pour qu'un pair qui en détient une copie ne puisse pas le faire revenir.
class DeleteOwnContentUsecase extends Usecase<DeleteOwnContentParams, DeleteOwnContentFailure, void> {
  /// Crée un [DeleteOwnContentUsecase].
  DeleteOwnContentUsecase(this._contentRepository, this._deleteContentsService, this._errorLogRepository);

  final ContentRepository _contentRepository;
  final DeleteContentsService _deleteContentsService;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<DeleteOwnContentFailure, void>> call(DeleteOwnContentParams params) async {
    try {
      final content = await _contentRepository.getById(params.contentId);
      if (content == null) {
        return const Left(DeleteOwnContentFailure.notFound);
      }
      if (!content.isOwned) {
        return const Left(DeleteOwnContentFailure.notOwned);
      }

      final result = await _deleteContentsService(DeleteContentsParams(contents: [content]));
      return result.fold<Either<DeleteOwnContentFailure, void>>(
        onFailure: (DeleteContentsFailure failure) => Left(switch (failure) {
          DeleteContentsFailure.storageError => DeleteOwnContentFailure.storageError,
          DeleteContentsFailure.unknown => DeleteOwnContentFailure.unknown,
        }),
        onSuccess: (_) => const Right(null),
      );
    } on DataException catch (error, stackTrace) {
      AppLogger.error('DeleteOwnContentUsecase', error, stackTrace);
      return const Left(DeleteOwnContentFailure.storageError);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('DeleteOwnContentUsecase', error, stackTrace);
      return const Left(DeleteOwnContentFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('DeleteOwnContentUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'DeleteOwnContentUsecase', error: error, stackTrace: stackTrace);
      return const Left(DeleteOwnContentFailure.unknown);
    }
  }
}
