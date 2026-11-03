import 'package:bedbug/usecases/signature/get_signature_suggestions/get_signature_suggestions.usecase.dart';

/// Échecs possibles du [GetSignatureSuggestionsUsecase].
enum GetSignatureSuggestionsFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la recherche de suggestions.
  unknown,
}
