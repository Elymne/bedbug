/// Contrat du service d'enregistrement d'image dans la galerie du téléphone.
///
/// Isolé derrière une interface pour que le domaine décide quand enregistrer
/// une image sans dépendre du plugin natif utilisé, ni du format attendu par
/// chaque galerie.
abstract class ImageGalleryGateway {
  /// Enregistre l'image située à [sourcePath] dans la galerie du téléphone.
  ///
  /// L'image est convertie si besoin dans un format accepté par toutes les
  /// galeries. Lève une `GalleryException` en cas d'échec, avec
  /// `isAccessDenied` à `true` si l'utilisateur refuse l'accès.
  ///
  /// - [sourcePath] : chemin absolu de l'image à enregistrer.
  Future<void> saveImage(String sourcePath);
}
