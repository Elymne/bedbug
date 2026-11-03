import 'package:bedbug/core/domain/value_object.dart';
import 'package:bedbug/gateways/exchange/exchange_transport/exchange_transport.gateway.dart';
import 'package:bedbug/resources/exchange/exchange_log/exchange_log_outcome.enum.dart';

/// Résultat d'une demande de démarrage de [PeerLinkGateway].
enum PeerLinkStartStatus {
  /// La recherche de pairs a démarré.
  started,

  /// Le Bluetooth du téléphone est désactivé.
  bluetoothOff,

  /// Les permissions nécessaires ne sont pas accordées.
  permissionDenied,

  /// Le téléphone ne permet pas la recherche de pairs.
  unavailable,
}

/// Contrat de la recherche de pairs : trouver les téléphones proches et s'y connecter.
///
/// Une connexion établie arrive sous forme d'un [ExchangeTransportGateway] : le reste de l'app ne sait rien de la
/// radio qui l'a produite.
abstract class PeerLinkGateway {
  /// Connexions établies avec des pairs, à mesure qu'elles arrivent.
  Stream<ExchangeTransportGateway> get connections;

  /// Pairs vus sans qu'un échange ait pu commencer, à mesure qu'ils arrivent.
  ///
  /// Sans eux, le journal des échanges ne dirait rien des rencontres qui n'aboutissent pas.
  Stream<PeerAttempt> get attempts;

  /// Signale que la recherche s'est arrêtée, y compris sans que l'app l'ait demandé.
  ///
  /// L'utilisateur peut l'arrêter depuis la notification, et le Bluetooth peut être coupé à tout moment.
  Stream<void> get stopped;

  /// Demande les permissions nécessaires, et retourne `true` si elles sont accordées.
  Future<bool> requestPermissions();

  /// Démarre la recherche de pairs. Si elle tourne déjà, se raccorde simplement à elle.
  Future<PeerLinkStartStatus> start();

  /// Arrête la recherche de pairs et ferme la connexion en cours.
  Future<void> stop();
}

/// Pair vu par la recherche, mais avec qui aucune connexion n'a abouti.
class PeerAttempt extends ValueObject {
  /// Crée un [PeerAttempt].
  ///
  /// - [peerAddress] : adresse Bluetooth du pair.
  /// - [outcome] : raison pour laquelle l'échange n'a pas eu lieu.
  const PeerAttempt({required this.peerAddress, required this.outcome});

  /// Adresse Bluetooth du pair.
  final String peerAddress;

  /// Raison pour laquelle l'échange n'a pas eu lieu.
  final ExchangeLogOutcome outcome;

  @override
  bool operator ==(Object other) {
    return other is PeerAttempt && other.peerAddress == peerAddress && other.outcome == outcome;
  }

  @override
  int get hashCode {
    return Object.hash(peerAddress, outcome);
  }
}
