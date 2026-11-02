import 'package:bedbug/services/content/delete_contents/delete_contents.service.dart';

/// Échecs possibles du [DeleteContentsService].
enum DeleteContentsFailure {
  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la suppression.
  unknown,
}
