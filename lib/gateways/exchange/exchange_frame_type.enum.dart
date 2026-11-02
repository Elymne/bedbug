/// Taille maximale de la charge utile d'une trame de contrôle ou de négociation ([ExchangeFrameType.offer] et
/// [ExchangeFrameType.request]), en octets.
///
/// Une offre compressée pèse quelques kilo-octets : cette marge n'est jamais atteinte par un pair honnête.
const int maxExchangeNegotiationBytes = 64 * 1024;

/// Taille maximale d'un lot sur le fil, en octets, une fois compressé.
///
/// Le budget de 200 Ko de contenus se compresse bien en dessous, et 1 Mo laisse la place aux réactions. Au-delà,
/// le transfert ne tiendrait pas dans une rencontre, et la trame serait une façon de saturer la mémoire du pair.
const int maxExchangeDataBytes = 1024 * 1024;

/// Types de trames du protocole d'échange.
enum ExchangeFrameType {
  /// Présentation : version du protocole, envoyée par les deux appareils dès la connexion.
  hello(0x01, 64),

  /// Offre : ce que l'appareil propose, encodée par `BuildExchangeOfferUsecase`.
  offer(0x02, maxExchangeNegotiationBytes),

  /// Demande : ce que l'appareil choisit dans l'offre du pair, encodée par `SelectFromExchangeOfferUsecase`.
  request(0x03, maxExchangeNegotiationBytes),

  /// Lot : réponse à la demande du pair, encodée par `BuildExchangeBundleUsecase`.
  data(0x04, maxExchangeDataBytes),

  /// Accusé : le lot du pair a été traité. Dernière trame d'un échange réussi.
  done(0x05, 0),

  /// Abandon : l'appareil met fin à l'échange. Permet au pair d'arrêter tout de suite plutôt que d'attendre.
  error(0x06, 0);

  /// Crée un [ExchangeFrameType].
  ///
  /// - [value] : valeur du type sur le fil.
  /// - [maxPayloadBytes] : taille maximale de la charge utile, en octets.
  const ExchangeFrameType(this.value, this.maxPayloadBytes);

  /// Valeur du type sur le fil.
  final int value;

  /// Taille maximale de la charge utile, en octets.
  ///
  /// Vérifiée dès l'en-tête, avant de réserver la mémoire : un pair ne peut pas annoncer 4 Go pour saturer l'appareil.
  final int maxPayloadBytes;

  /// Retourne le type de valeur [value], ou `null` s'il est inconnu.
  ///
  /// - [value] : valeur lue sur le fil.
  static ExchangeFrameType? fromValue(int value) {
    for (final type in values) {
      if (type.value == value) {
        return type;
      }
    }
    return null;
  }
}
