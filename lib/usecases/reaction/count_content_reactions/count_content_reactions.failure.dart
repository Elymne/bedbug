import 'package:bedbug/usecases/reaction/count_content_reactions/count_content_reactions.usecase.dart';

/// Échecs possibles du [CountContentReactionsUsecase].
enum CountContentReactionsFailure {
  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors du comptage.
  unknown,
}
