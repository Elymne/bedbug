import 'package:bedbug/usecases/exchange/stop_peer_link/stop_peer_link.usecase.dart';

/// Échecs possibles du [StopPeerLinkUsecase].
enum StopPeerLinkFailure {
  /// Le service d'échange n'a pas répondu.
  unavailable,
}
