import 'package:bedbug/usecases/feed/mark_content_viewed/mark_content_viewed.usecase.dart';

/// Échecs possibles du [MarkContentViewedUsecase].
enum MarkContentViewedFailure {
  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de l'enregistrement.
  unknown,
}
