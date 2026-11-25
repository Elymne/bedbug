/// Étape d'un échange avec un pair, telle que notée dans le journal des échanges.
///
/// Sert à savoir où un échange interrompu s'est arrêté : l'étape notée est celle que le téléphone attendait quand
/// l'échange a pris fin. Le journal a son propre vocabulaire, indépendant du protocole qui transporte les échanges.
enum ExchangeLogStep {
  /// Présentation des deux appareils.
  hello(0),

  /// Offre de contenus du pair.
  offer(1),

  /// Demande du pair dans l'offre du téléphone.
  request(2),

  /// Lot de contenus du pair.
  data(3),

  /// Accusé de fin du pair.
  done(4);

  /// Crée un [ExchangeLogStep].
  ///
  /// - [value] : valeur persistée.
  const ExchangeLogStep(this.value);

  /// Valeur persistée, stable indépendamment de l'ordre de déclaration.
  final int value;
}
