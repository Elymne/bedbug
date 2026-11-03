import 'package:bedbug/usecases/content/get_drawing_draft/get_drawing_draft.usecase.dart';

/// Échecs possibles du [GetDrawingDraftUsecase].
enum GetDrawingDraftFailure {
  /// Le brouillon lu est corrompu.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue.
  unknown,
}
