import 'package:bedbug/usecases/feed/recalculate_display_scores/recalculate_display_scores.usecase.dart';

/// Échecs possibles du [RecalculateDisplayScoresUsecase].
enum RecalculateDisplayScoresFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors du recalcul des scores.
  unknown,
}
