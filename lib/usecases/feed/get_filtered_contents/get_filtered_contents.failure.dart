import 'package:bedbug/usecases/feed/get_filtered_contents/get_filtered_contents.usecase.dart';

/// Échecs possibles du [GetFilteredContentsUsecase].
enum GetFilteredContentsFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la récupération des contenus.
  unknown,
}
