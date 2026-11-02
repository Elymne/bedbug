import 'package:bedbug/usecases/feed/get_flair_suggestions/get_flair_suggestions.usecase.dart';

/// Échecs possibles du [GetFlairSuggestionsUsecase].
enum GetFlairSuggestionsFailure {
  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la recherche de suggestions.
  unknown,
}
