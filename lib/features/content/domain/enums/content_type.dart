/// Type de contenu créé par l'utilisateur.
enum ContentType {
  /// Contenu textuel (titre + corps).
  text(0),

  /// Contenu image avec titre et description optionnels.
  image(1),

  /// Contenu lien avec métadonnées Open Graph optionnelles.
  link(2);

  const ContentType(this.value);

  /// Valeur entière stable indépendamment de l'ordre de déclaration.
  final int value;
}
