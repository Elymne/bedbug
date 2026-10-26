import 'package:bedbug/features/content/domain/entities/comment.dart';
import 'package:bedbug/features/content/domain/extensions/comment_text_extension.dart';
import 'package:bedbug/features/content/domain/repositories/comment_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_comment_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SaveCommentUsecase].
final saveCommentUsecaseProvider = Provider<SaveCommentUsecase>((ref) {
  return SaveCommentUsecase(ref.read(commentRepositoryProvider));
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
  SaveCommentUsecase(this._commentRepository);

  final CommentRepository _commentRepository;

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
        authorId: params.comment.authorId,
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
      return const Left(SaveCommentFailure.unknown);
    }
  }
}

/// Échecs possibles du [SaveCommentUsecase].
enum SaveCommentFailure {
  /// Le corps est vide ou trop long.
  invalidComment,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de l'enregistrement.
  unknown,
}

/// Paramètres du [SaveCommentUsecase].
class SaveCommentParams extends Params {
  /// Crée des [SaveCommentParams].
  ///
  /// - [comment] : commentaire à enregistrer, avant normalisation.
  const SaveCommentParams({required this.comment});

  /// Commentaire à enregistrer, avant normalisation.
  final Comment comment;
}
