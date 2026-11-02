import 'package:bedbug/usecases/feed/get_contents_by_flair/get_contents_by_flair.usecase.dart';

/// Échecs possibles du [GetContentsByFlairUsecase].
enum GetContentsByFlairFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la récupération des contenus.
  unknown,
}
