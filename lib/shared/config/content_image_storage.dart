/// Nom du sous-dossier, dans le dossier de documents de l'application,
/// où sont stockés les fichiers image des `ImageContent`.
///
/// Centralisé ici car lu et écrit depuis plusieurs endroits (écran de
/// création, tiles, écran de détail) qui doivent tous s'accorder sur le
/// même chemin.
const String contentImagesFolder = 'content_images';
