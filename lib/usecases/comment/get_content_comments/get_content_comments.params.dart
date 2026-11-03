import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/usecases/comment/get_content_comments/get_content_comments.usecase.dart';

/// Paramètres du [GetContentCommentsUsecase].
class GetContentCommentsParams extends Params {
  /// Crée des [GetContentCommentsParams].
  ///
  /// - [contentId] : identifiant du contenu dont on veut les commentaires.
  const GetContentCommentsParams({required this.contentId});

  /// Identifiant du contenu dont on veut les commentaires.
  final String contentId;
}
