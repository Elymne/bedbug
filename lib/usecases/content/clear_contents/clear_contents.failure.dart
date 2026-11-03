import 'package:bedbug/usecases/content/clear_contents/clear_contents.usecase.dart';

/// Échecs possibles du [ClearContentsUsecase].
enum ClearContentsFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la suppression des contenus.
  unknown,
}
