import 'package:bedbug/usecases/comment/get_content_comments/get_content_comments.usecase.dart';

/// Échecs possibles du [GetContentCommentsUsecase].
enum GetContentCommentsFailure {
  /// Un commentaire stocké est invalide ou corrompu.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la lecture.
  unknown,
}
