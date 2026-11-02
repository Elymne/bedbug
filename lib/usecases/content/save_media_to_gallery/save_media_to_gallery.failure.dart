import 'package:bedbug/usecases/content/save_media_to_gallery/save_media_to_gallery.usecase.dart';

/// Échecs possibles du [SaveMediaToGalleryUsecase].
enum SaveMediaToGalleryFailure {
  /// Le fichier n'est pas une image ou une vidéo d'un format accepté.
  unsupportedFormat,

  /// L'utilisateur a refusé l'accès à sa galerie.
  accessDenied,

  /// Le média n'a pas pu être écrit (stockage plein, format refusé par la galerie, erreur native).
  saveError,
}
