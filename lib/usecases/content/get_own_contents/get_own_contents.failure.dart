import 'package:bedbug/usecases/content/get_own_contents/get_own_contents.usecase.dart';

/// Échecs possibles du [GetOwnContentsUsecase].
enum GetOwnContentsFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la récupération des contenus.
  unknown,
}
