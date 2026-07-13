/// Provenance d'un contenu, utilisée comme facteur d'entrée pour le calcul
/// des scores de diffusion et de rétention d'un contenu.
///
/// Ne porte aucune notion d'ordre intrinsèque : c'est la pondération de
/// chaque score qui interprète cette provenance selon son propre besoin.
enum ContentOrigin {
  /// Contenu public sans sub associé.
  public(0),

  /// Contenu provenant d'un sub auquel l'utilisateur est abonné.
  subscribed(1),

  /// Contenu ajouté en favori par l'utilisateur.
  favorited(2),

  /// Contenu créé par l'utilisateur lui-même.
  owned(3);

  const ContentOrigin(this.value);

  /// Valeur entière persistée. Stable indépendamment de l'ordre de déclaration.
  final int value;
}
