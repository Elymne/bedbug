/// Type de contenu créé par l'utilisateur.
enum ContentType {
  /// Contenu textuel (titre + corps).
  text(0),

  /// Contenu média (images, gifs, vidéos hébergés en ligne) avec titre et description optionnelle.
  ///
  /// Reprend la valeur de l'ancien type image, qu'il remplace.
  media(1),

  /// Contenu lien avec métadonnées Open Graph optionnelles.
  link(2);

  const ContentType(this.value);

  /// Valeur entière stable indépendamment de l'ordre de déclaration.
  final int value;
}
