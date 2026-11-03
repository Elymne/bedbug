import 'package:bedbug/usecases/exchange/recalculate_broadcast_scores/recalculate_broadcast_scores.usecase.dart';

/// Échecs possibles du [RecalculateBroadcastScoresUsecase].
enum RecalculateBroadcastScoresFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors du recalcul des scores.
  unknown,
}
