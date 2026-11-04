/// Rapport entre l'image d'un dessin et son repère : un pixel pour deux points.
///
/// Fixe, quel que soit l'écran : un remplissage se calcule sur cette image,
/// et doit donner la même zone sur tous les téléphones. Affichée sans
/// lissage, elle donne aussi aux dessins leur rendu « pixel » assumé.
const double drawingRasterScale = 0.5;
