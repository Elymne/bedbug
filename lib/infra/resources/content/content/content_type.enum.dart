/// Type concret d'un contenu.
///
/// Sa [value] est le discriminant stocké en base et échangé entre pairs pour savoir quel sous-type de `Content`
/// reconstruire. Elle sert aussi au choix du type à l'écran de création.
enum ContentType {
  /// Contenu textuel (titre + corps).
  text(0),

  /// Contenu média (images, gifs, vidéos hébergés en ligne) avec titre et description optionnelle.
  ///
  /// Reprend la valeur de l'ancien type image, qu'il remplace.
  media(1),

  /// Contenu lien avec métadonnées Open Graph optionnelles.
  link(2),

  /// Dessin fait dans l'app, au pinceau, avec un titre.
  drawing(3);

  const ContentType(this.value);

  /// Valeur entière stable indépendamment de l'ordre de déclaration.
  final int value;
}
