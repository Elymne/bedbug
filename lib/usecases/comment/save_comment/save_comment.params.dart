import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/resources/content/comment/comment.entity.dart';
import 'package:bedbug/usecases/comment/save_comment/save_comment.usecase.dart';

/// Paramètres du [SaveCommentUsecase].
class SaveCommentParams extends Params {
  /// Crée des [SaveCommentParams].
  ///
  /// - [comment] : commentaire à enregistrer, avant normalisation.
  const SaveCommentParams({required this.comment});

  /// Commentaire à enregistrer, avant normalisation.
  final Comment comment;
}
