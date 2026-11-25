import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/service.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.drift.dart';
import 'package:bedbug/infra/resources/data.exception.dart';
import 'package:bedbug/infra/resources/datasource.exception.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.drift.dart';
import 'package:bedbug/logic/services/content/delete_contents/delete_contents.failure.dart';
import 'package:bedbug/logic/services/content/delete_contents/delete_contents.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [DeleteContentsService].
final deleteContentsServiceProvider = Provider<DeleteContentsService>((ref) {
  return DeleteContentsService(ref.read(contentRepositoryProvider), ref.read(errorLogRepositoryProvider));
});

/// Supprime des contenus du téléphone, avec tout ce qui s'y rattache.
///
/// Un contenu ne vit pas seul : ses réactions, ses commentaires et la trace qu'il a été vu à l'écran le suivent, sans
/// quoi ils resteraient orphelins. Il est aussi mémorisé comme déjà vu : sans cette mémoire, le prochain pair qui le
/// propose le ferait retélécharger, en boucle. Que l'utilisateur supprime son contenu, que le stockage soit plein ou
/// qu'un domaine ne soit plus de confiance, la suppression est donc toujours la même, et c'est ce service qui la fait.
///
/// Les données rattachées partent avec le contenu dans le stockage lui-même ; la mémoire « déjà vu » est écrite dans
/// la même opération que la suppression. Les contenus déjà absents sont sans effet, sinon d'être mémorisés.
class DeleteContentsService extends Service<DeleteContentsParams, DeleteContentsFailure, void> {
  /// Crée un [DeleteContentsService].
  DeleteContentsService(this._contentRepository, this._errorLogRepository);

  /// Repository des contenus, qui supprime et mémorise ensemble.
  final ContentRepository _contentRepository;

  /// Journal des erreurs inattendues.
  final ErrorLogRepository _errorLogRepository;

  /// Exécute l'opération décrite par la classe ; les échecs prévus sont retournés en [Left], jamais levés.
  @override
  Future<Either<DeleteContentsFailure, void>> call(DeleteContentsParams params) async {
    try {
      if (params.contentIds.isEmpty) {
        return const Right(null);
      }
      await _contentRepository.deleteManyAsSeen(params.contentIds, DateTime.now());
      return const Right(null);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('DeleteContentsService', error, stackTrace);
      return const Left(DeleteContentsFailure.storageError);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('DeleteContentsService', error, stackTrace);
      return const Left(DeleteContentsFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('DeleteContentsService', error, stackTrace);
      await _errorLogRepository.record(source: 'DeleteContentsService', error: error, stackTrace: stackTrace);
      return const Left(DeleteContentsFailure.unknown);
    }
  }
}
