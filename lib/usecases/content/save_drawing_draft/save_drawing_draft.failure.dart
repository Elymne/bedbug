import 'package:bedbug/usecases/content/save_drawing_draft/save_drawing_draft.usecase.dart';

/// Échecs possibles du [SaveDrawingDraftUsecase].
enum SaveDrawingDraftFailure {
  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue.
  unknown,
}
