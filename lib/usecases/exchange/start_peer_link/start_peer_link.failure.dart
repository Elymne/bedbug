import 'package:bedbug/usecases/exchange/start_peer_link/start_peer_link.usecase.dart';

/// Échecs possibles du [StartPeerLinkUsecase].
enum StartPeerLinkFailure {
  /// L'utilisateur a refusé les permissions.
  permissionDenied,

  /// Le Bluetooth du téléphone est désactivé.
  bluetoothOff,

  /// Le téléphone ne permet pas la recherche de pairs, ou Android l'a refusée.
  unavailable,
}
