import 'package:bedbug/usecases/feed/get_contents_by_signatures/get_contents_by_signatures.usecase.dart';

/// Échecs possibles du [GetContentsBySignaturesUsecase].
enum GetContentsBySignaturesFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la récupération des contenus.
  unknown,
}
