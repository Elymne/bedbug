import 'package:bedbug/features/exchange/domain/gateways/exchange_transport_gateway.dart';

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
