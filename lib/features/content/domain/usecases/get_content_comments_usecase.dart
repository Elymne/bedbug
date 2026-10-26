import 'dart:math';

import 'package:bedbug/features/content/domain/entities/comment.dart';
import 'package:bedbug/features/content/domain/repositories/comment_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_comment_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetContentCommentsUsecase].
final getContentCommentsUsecaseProvider = Provider<GetContentCommentsUsecase>((ref) {
  return GetContentCommentsUsecase(ref.read(commentRepositoryProvider), Random());
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
  GetContentCommentsUsecase(this._commentRepository, this._random);

  final CommentRepository _commentRepository;
  final Random _random;

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
      return const Left(GetContentCommentsFailure.unknown);
    }
  }
}

/// Échecs possibles du [GetContentCommentsUsecase].
enum GetContentCommentsFailure {
  /// Un commentaire stocké est invalide ou corrompu.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la lecture.
  unknown,
}

/// Paramètres du [GetContentCommentsUsecase].
class GetContentCommentsParams extends Params {
  /// Crée des [GetContentCommentsParams].
  ///
  /// - [contentId] : identifiant du contenu dont on veut les commentaires.
  const GetContentCommentsParams({required this.contentId});

  /// Identifiant du contenu dont on veut les commentaires.
  final String contentId;
}
