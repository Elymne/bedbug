import 'package:bedbug/usecases/reaction/get_content_reactions/get_content_reactions.usecase.dart';

/// Échecs possibles du [GetContentReactionsUsecase].
enum GetContentReactionsFailure {
  /// Une réaction stockée est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la lecture.
  unknown,
}
