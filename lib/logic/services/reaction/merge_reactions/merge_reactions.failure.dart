import 'package:bedbug/logic/services/reaction/merge_reactions/merge_reactions.service.dart';

/// Échecs possibles du [MergeReactionsService].
///
/// Une réaction invalide n'est pas un échec : elle est seulement écartée, pour ne pas faire tomber le reste du lot.
enum MergeReactionsFailure {
  /// Erreur de la couche de stockage locale : aucune réaction du lot n'a été écrite.
  storageError,

  /// Erreur inattendue lors de l'intégration.
  unknown,
}
