import 'dart:math';

import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/content/comment.entity.dart';
import 'package:bedbug/resources/content/comment.repository.dart';
import 'package:bedbug/resources/content/comment.repository.hive.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log.repository.hive.dart';
import 'package:bedbug/usecases/comment/get_content_comments/get_content_comments.failure.dart';
import 'package:bedbug/usecases/comment/get_content_comments/get_content_comments.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetContentCommentsUsecase].
final getContentCommentsUsecaseProvider = Provider<GetContentCommentsUsecase>((ref) {
  return GetContentCommentsUsecase(ref.read(commentRepositoryProvider), Random(), ref.read(errorLogRepositoryProvider));
});

/// Retourne les commentaires d'un contenu, dans un ordre aléatoire.
///
/// Les commentaires sont stockés à part du contenu (ils voyagent seuls entre
/// pairs) : la page de détail doit donc les charger séparément. Ils sont
/// mélangés plutôt que triés : sans classement, aucun commentaire n'est
/// favorisé par sa date ou son auteur, et chaque visite en met d'autres en
/// avant.
class GetContentCommentsUsecase extends Usecase<GetContentCommentsParams, GetContentCommentsFailure, List<Comment>> {
  /// Crée un [GetContentCommentsUsecase].
  GetContentCommentsUsecase(this._commentRepository, this._random, this._errorLogRepository);

  final CommentRepository _commentRepository;
  final Random _random;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<GetContentCommentsFailure, List<Comment>>> call(GetContentCommentsParams params) async {
    try {
      final comments = await _commentRepository.getAllByContentId(params.contentId);
      return Right(comments..shuffle(_random));
    } on DataException catch (error, stackTrace) {
      AppLogger.error('GetContentCommentsUsecase', error, stackTrace);
      return const Left(GetContentCommentsFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('GetContentCommentsUsecase', error, stackTrace);
      return const Left(GetContentCommentsFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('GetContentCommentsUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'GetContentCommentsUsecase', error: error, stackTrace: stackTrace);
      return const Left(GetContentCommentsFailure.unknown);
    }
  }
}
