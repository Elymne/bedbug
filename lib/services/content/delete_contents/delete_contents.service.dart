import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/service.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/content/comment/comment.repository.dart';
import 'package:bedbug/resources/content/comment/comment.repository.hive.dart';
import 'package:bedbug/resources/content/content/content.repository.dart';
import 'package:bedbug/resources/content/content/content.repository.hive.dart';
import 'package:bedbug/resources/content/reaction/reaction.repository.dart';
import 'package:bedbug/resources/content/reaction/reaction.repository.hive.dart';
import 'package:bedbug/resources/content/seen_content/seen_content.entity.dart';
import 'package:bedbug/resources/content/seen_content/seen_content.repository.dart';
import 'package:bedbug/resources/content/seen_content/seen_content.repository.hive.dart';
import 'package:bedbug/resources/content/storage/storage.repository.dart';
import 'package:bedbug/resources/content/storage/storage.repository.hive.dart';
import 'package:bedbug/resources/content/viewed_content/viewed_content.repository.dart';
import 'package:bedbug/resources/content/viewed_content/viewed_content.repository.hive.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.hive.dart';
import 'package:bedbug/services/content/delete_contents/delete_contents.failure.dart';
import 'package:bedbug/services/content/delete_contents/delete_contents.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [DeleteContentsService].
final deleteContentsServiceProvider = Provider<DeleteContentsService>((ref) {
  return DeleteContentsService(
    ref.read(contentRepositoryProvider),
    ref.read(reactionRepositoryProvider),
    ref.read(commentRepositoryProvider),
    ref.read(seenContentRepositoryProvider),
    ref.read(viewedContentRepositoryProvider),
    ref.read(storageRepositoryProvider),
    ref.read(errorLogRepositoryProvider),
  );
});

/// Supprime des contenus du téléphone, avec tout ce qui s'y rattache.
///
/// Un contenu ne vit pas seul : ses réactions, ses commentaires, la trace qu'il a été vu à l'écran et son poids dans
/// le total du stockage le suivent. Le supprimer à moitié laisserait des réactions orphelines ou un poids faux. Il
/// est aussi mémorisé comme déjà vu : sans cette mémoire, le prochain pair qui le propose le ferait retélécharger,
/// en boucle. Que l'utilisateur supprime son contenu, que le stockage soit plein ou qu'un domaine ne soit plus de
/// confiance, la suppression est donc toujours la même, et c'est ce service qui la fait.
///
/// Les contenus déjà absents sont sans effet, sauf sur le poids : l'appelant ne passe que des contenus qu'il vient
/// de lire.
class DeleteContentsService extends Service<DeleteContentsParams, DeleteContentsFailure, void> {
  /// Crée un [DeleteContentsService].
  DeleteContentsService(
    this._contentRepository,
    this._reactionRepository,
    this._commentRepository,
    this._seenContentRepository,
    this._viewedContentRepository,
    this._storageRepository,
    this._errorLogRepository,
  );

  final ContentRepository _contentRepository;
  final ReactionRepository _reactionRepository;
  final CommentRepository _commentRepository;
  final SeenContentRepository _seenContentRepository;
  final ViewedContentRepository _viewedContentRepository;
  final StorageRepository _storageRepository;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<DeleteContentsFailure, void>> call(DeleteContentsParams params) async {
    try {
      if (params.contents.isEmpty) {
        return const Right(null);
      }

      final ids = params.contents.map((content) => content.id).toList();
      final seenAt = DateTime.now();
      await _seenContentRepository.addMany([
        for (final id in ids) SeenContent(id: id, createdAt: seenAt, updatedAt: seenAt),
      ]);
      await _viewedContentRepository.deleteMany(ids);
      await _reactionRepository.deleteAllByContentIds(ids.toSet());
      await _commentRepository.deleteAllByContentIds(ids.toSet());
      await _contentRepository.deleteMany(ids);
      final freedBytes = params.contents.fold<int>(0, (total, content) => total + content.sizeInBytes);
      await _storageRepository.adjustCurrentSizeInBytes(-freedBytes);
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
