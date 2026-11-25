import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/infra/resources/content/comment/comment.config.dart';
import 'package:bedbug/infra/resources/content/comment/comment.entity.dart';
import 'package:bedbug/infra/resources/content/comment/comment.repository.dart';
import 'package:bedbug/infra/resources/content/comment/comment.repository.drift.dart';
import 'package:bedbug/infra/resources/data.exception.dart';
import 'package:bedbug/infra/resources/datasource.exception.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.drift.dart';
import 'package:bedbug/logic/usecases/comment/save_comment/save_comment.failure.dart';
import 'package:bedbug/logic/usecases/comment/save_comment/save_comment.params.dart';
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
///
/// L'insertion et l'élagage sont écrits ensemble par le repository : une panne entre les deux ne peut pas laisser un
/// contenu au-delà de son plafond.
class SaveCommentUsecase extends Usecase<SaveCommentParams, SaveCommentFailure, Comment> {
  /// Crée un [SaveCommentUsecase].
  ///
  /// - [_commentRepository] : enregistrement des commentaires.
  /// - [_errorLogRepository] : journal des erreurs inattendues.
  SaveCommentUsecase(this._commentRepository, this._errorLogRepository);

  /// Enregistrement des commentaires.
  final CommentRepository _commentRepository;

  /// Journal des erreurs inattendues.
  final ErrorLogRepository _errorLogRepository;

  /// Valide le corps du commentaire de [params], puis l'enregistre dans la limite de son contenu.
  ///
  /// Retourne le commentaire stocké : celui déjà présent si le même identifiant a déjà été reçu.
  ///
  /// - [params] : commentaire à enregistrer.
  @override
  Future<Either<SaveCommentFailure, Comment>> call(SaveCommentParams params) async {
    try {
      final body = params.comment.body.trim();
      if (!Comment.isValidBody(body)) {
        return const Left(SaveCommentFailure.invalidComment);
      }

      final comment = Comment(
        id: params.comment.id,
        createdAt: params.comment.createdAt,
        updatedAt: params.comment.updatedAt,
        contentId: params.comment.contentId,
        signatureId: params.comment.signatureId,
        body: body,
      );
      final stored = await _commentRepository.addOneKeepingLatest(comment, maxPerContent: maxCommentsPerContent);

      return Right(stored);
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
