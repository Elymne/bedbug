import 'package:bedbug/usecases/reaction/save_reaction/save_reaction.usecase.dart';

/// Échecs possibles du [SaveReactionUsecase].
enum SaveReactionFailure {
  /// Le bedbug contient un mot, ou la bulle est vide, trop longue ou sur plusieurs lignes.
  invalidReaction,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de l'enregistrement.
  unknown,
}
