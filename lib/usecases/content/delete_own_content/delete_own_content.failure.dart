import 'package:bedbug/usecases/content/delete_own_content/delete_own_content.usecase.dart';

/// Échecs possibles du [DeleteOwnContentUsecase].
enum DeleteOwnContentFailure {
  /// Aucun contenu ne porte cet identifiant (déjà supprimé, par exemple).
  notFound,

  /// Le contenu n'a pas été créé sur cet appareil : sa suppression est refusée.
  notOwned,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la suppression.
  unknown,
}
