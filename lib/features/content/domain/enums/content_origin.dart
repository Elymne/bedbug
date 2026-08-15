/// Provenance d'un contenu, utilisée comme facteur d'entrée pour le calcul
/// des scores de diffusion et de rétention d'un contenu.
///
/// Ne porte aucune notion d'ordre intrinsèque : c'est la pondération de
/// chaque score qui interprète cette provenance selon son propre besoin.
enum ContentOrigin {
  /// Contenu public sans sub associé.
  public(0, survivalHalfLifeDays: 7, broadcastHalfLifeDays: 2, displayHalfLifeDays: 3),

  /// Contenu provenant d'un sub auquel l'utilisateur est abonné.
  subscribed(1, survivalHalfLifeDays: 21, broadcastHalfLifeDays: 5, displayHalfLifeDays: 7),

  /// Contenu ajouté en favori par l'utilisateur.
  favorited(2, survivalHalfLifeDays: 90, broadcastHalfLifeDays: 14, displayHalfLifeDays: 30),

  /// Contenu créé par l'utilisateur lui-même.
  owned(
    3,
    survivalHalfLifeDays: double.infinity,
    broadcastHalfLifeDays: double.infinity,
    displayHalfLifeDays: double.infinity,
  );

  const ContentOrigin(
    this.value, {
    required this.survivalHalfLifeDays,
    required this.broadcastHalfLifeDays,
    required this.displayHalfLifeDays,
  });

  /// Valeur entière persistée. Stable indépendamment de l'ordre de déclaration.
  final int value;

  /// Demi-vie en jours utilisée par la décroissance exponentielle du
  /// `survivalScore`. Plus la valeur est grande, plus le contenu résiste
  /// longtemps à la suppression automatique.
  ///
  /// Sans effet pour [owned], dont le score reste fixe à `1.0`.
  final double survivalHalfLifeDays;

  /// Demi-vie en jours utilisée par la décroissance exponentielle du
  /// `broadcastScore`. Plus la valeur est grande, plus le contenu reste
  /// longtemps prioritaire à l'envoi BLE/WIFI.
  ///
  /// Volontairement bien plus courte que [survivalHalfLifeDays] : la
  /// priorité de diffusion répond à une fenêtre de propagation (un contenu
  /// se diffuse tant qu'il est « chaud »), alors que la conservation répond
  /// à une notion de valeur perçue qui s'érode beaucoup plus lentement.
  ///
  /// Sans effet pour [owned], dont le score reste fixe à `1.0`.
  final double broadcastHalfLifeDays;

  /// Demi-vie en jours utilisée par la décroissance exponentielle du
  /// `displayScore`. Plus la valeur est grande, plus le contenu reste
  /// longtemps mis en avant dans la liste de la page d'accueil.
  ///
  /// Intermédiaire entre [broadcastHalfLifeDays] et [survivalHalfLifeDays] :
  /// l'ordre d'affichage doit rester dominé par la fraîcheur (comme la
  /// diffusion), sans pour autant faire disparaître aussi vite un contenu
  /// favori que l'utilisateur veut continuer à voir en haut de son fil.
  ///
  /// Sans effet pour [owned], dont le score reste fixe à `1.0` : le contenu
  /// de l'utilisateur reste toujours en tête de son propre fil.
  final double displayHalfLifeDays;
}
