import 'package:bedbug/usecases/storage/recalculate_survival_scores/recalculate_survival_scores.usecase.dart';

/// Échecs possibles du [RecalculateSurvivalScoresUsecase].
enum RecalculateSurvivalScoresFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors du recalcul des scores.
  unknown,
}
