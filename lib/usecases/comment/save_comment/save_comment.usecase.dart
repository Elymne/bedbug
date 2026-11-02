import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/content/comment/comment.config.dart';
import 'package:bedbug/resources/content/comment/comment.entity.dart';
import 'package:bedbug/resources/content/comment/comment.extension.dart';
import 'package:bedbug/resources/content/comment/comment.repository.dart';
import 'package:bedbug/resources/content/comment/comment.repository.hive.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.hive.dart';
import 'package:bedbug/usecases/comment/save_comment/save_comment.failure.dart';
import 'package:bedbug/usecases/comment/save_comment/save_comment.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SaveCommentUsecase].
final saveCommentUsecaseProvider = Provider<SaveCommentUsecase>((ref) {
  return SaveCommentUsecase(ref.read(commentRepositoryProvider), ref.read(errorLogRepositoryProvider));
});

/// Enregistre un commentaire sur un contenu, en appliquant les règles qui bornent leur poids.
///
/// Les commentaires circulent de pair à pair sans identité vérifiable : ce
/// use case est le seul point d'entrée, qu'ils viennent de l'utilisateur ou,
/// plus tard, d'un pair. Il garantit ainsi partout que :
/// - le corps n'est pas vide et respecte sa longueur maximale (un
///   commentaire reçu ne passe par aucun formulaire) ;
/// - un même commentaire reçu plusieurs fois (même identifiant) n'est
///   enregistré qu'une fois ;
/// - un contenu ne garde que ses [maxCommentsPerContent] commentaires les
///   plus récents, pour que son poids reste borné quoi qu'envoient les pairs.
class SaveCommentUsecase extends Usecase<SaveCommentParams, SaveCommentFailure, Comment> {
  /// Crée un [SaveCommentUsecase].
  SaveCommentUsecase(this._commentRepository, this._errorLogRepository);

  final CommentRepository _commentRepository;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<SaveCommentFailure, Comment>> call(SaveCommentParams params) async {
    try {
      final body = params.comment.body.trim();
      if (!body.isValidCommentBody) {
        return const Left(SaveCommentFailure.invalidComment);
      }

      final existingComments = await _commentRepository.getAllByContentId(params.comment.contentId);
      for (final existing in existingComments) {
        if (existing.id == params.comment.id) {
          return Right(existing);
        }
      }

      final comment = Comment(
        id: params.comment.id,
        createdAt: params.comment.createdAt,
        updatedAt: params.comment.updatedAt,
        contentId: params.comment.contentId,
        signatureId: params.comment.signatureId,
        body: body,
      );
      await _commentRepository.addOne(comment);

      final keptComments = [comment, ...existingComments]
        ..sort((first, second) => second.createdAt.compareTo(first.createdAt));
      if (keptComments.length > maxCommentsPerContent) {
        final overflowIds = keptComments.skip(maxCommentsPerContent).map((overflow) => overflow.id).toList();
        await _commentRepository.deleteMany(overflowIds);
      }

      return Right(comment);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('SaveCommentUsecase', error, stackTrace);
      return const Left(SaveCommentFailure.storageError);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('SaveCommentUsecase', error, stackTrace);
      return const Left(SaveCommentFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('SaveCommentUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'SaveCommentUsecase', error: error, stackTrace: stackTrace);
      return const Left(SaveCommentFailure.unknown);
    }
  }
}
