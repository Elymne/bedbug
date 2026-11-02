import 'package:bedbug/usecases/comment/save_comment/save_comment.usecase.dart';

/// Échecs possibles du [SaveCommentUsecase].
enum SaveCommentFailure {
  /// Le corps est vide ou trop long.
  invalidComment,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de l'enregistrement.
  unknown,
}
