import 'package:bedbug/services/reaction/merge_reaction/merge_reaction.service.dart';

/// Échecs possibles du [MergeReactionService].
enum MergeReactionFailure {
  /// Le bedbug contient un mot, ou la bulle est vide, trop longue ou sur plusieurs lignes.
  invalidReaction,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de l'intégration.
  unknown,
}
