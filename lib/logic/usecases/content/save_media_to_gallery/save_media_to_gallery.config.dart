/// Taille maximale d'un média enregistré dans la galerie, en octets.
///
/// Plus large que pour l'affichage d'une image, pour laisser passer une
/// courte vidéo, mais bornée : le fichier est gardé en mémoire avant d'être
/// écrit.
const int maxGalleryMediaBytes = 50 * 1024 * 1024;
