/// Issue d'une rencontre avec un pair, telle que notée dans le journal des échanges.
enum ExchangeLogOutcome {
  /// L'échange a réussi.
  success(0),

  /// Le pair parle une autre version du protocole.
  incompatibleVersion(1),

  /// Le pair a envoyé des octets incohérents.
  protocolViolation(2),

  /// L'appareil n'a pas pu lire sa base ou écrire ce qu'il a reçu.
  localError(3),

  /// Le pair a abandonné l'échange.
  peerError(4),

  /// La connexion a été perdue.
  transportClosed(5),

  /// Le pair ne répond plus, ou l'échange a dépassé sa durée maximale.
  timeout(6),

  /// L'utilisateur a interrompu l'échange.
  cancelled(7),

  /// Le pair a été vu, mais la connexion n'a pas pu s'établir.
  connectionFailed(8),

  /// Le pair a été vu, mais ignoré : le dernier échange avec lui est trop récent.
  peerDelayed(9);

  const ExchangeLogOutcome(this.value);

  /// Valeur entière persistée. Stable indépendamment de l'ordre de déclaration.
  final int value;
}
