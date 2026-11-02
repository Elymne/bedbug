import 'package:bedbug/usecases/content/save_content/save_content.usecase.dart';

/// Échecs possibles du [SaveContentUsecase].
enum SaveContentFailure {
  /// Le contenu dépasse ses limites (dessin trop riche, mal formé) : il n'est pas enregistré.
  invalidContent,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la sauvegarde.
  unknown,
}
