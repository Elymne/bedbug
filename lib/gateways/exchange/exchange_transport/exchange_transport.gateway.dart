import 'dart:typed_data';

/// Contrat du tuyau d'octets entre deux appareils connectés, le temps d'un échange.
///
/// Le protocole de session ne doit rien savoir de la radio : il manipule un flux d'octets dans les deux sens, qu'il
/// passe par un canal L2CAP, par GATT ou par la mémoire dans les tests. Le découpage reçu est quelconque : un envoi
/// peut arriver en plusieurs morceaux, et plusieurs envois en un seul.
///
/// Une instance correspond à une connexion : elle n'est pas fournie par un provider, mais passée à la session.
abstract class ExchangeTransportGateway {
  /// Adresse Bluetooth du pair, notée dans le journal des échanges.
  String get peerAddress;

  /// Indique si ce téléphone a appelé le pair, pour le journal des échanges.
  bool get isInitiator;

  /// Octets reçus du pair, dans l'ordre d'envoi. Le flux se termine quand la connexion se ferme.
  ///
  /// Écoutable une seule fois. Il doit continuer à livrer pendant qu'un [send] est en attente : les deux appareils
  /// envoient en même temps, et s'il cessait de lire, chacun attendrait que l'autre ait fini.
  Stream<Uint8List> get incoming;

  /// Envoie [bytes] au pair, et se termine quand le transport est prêt à en recevoir d'autres.
  ///
  /// Attendre ce `Future` applique la contre-pression de la radio. Lève une exception si la connexion est fermée.
  ///
  /// - [bytes] : octets à envoyer.
  Future<void> send(Uint8List bytes);

  /// Signale que l'échange a réussi : le lot du pair a été importé.
  ///
  /// Le transport peut alors laisser ce pair tranquille un moment, alors qu'il le recontactera vite après un échec.
  /// Sans effet si la connexion est fermée.
  Future<void> confirmSuccess();

  /// Ferme la connexion. Sans effet si elle l'est déjà.
  Future<void> close();
}
