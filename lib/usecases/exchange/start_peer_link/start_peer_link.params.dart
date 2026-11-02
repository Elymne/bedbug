import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/usecases/exchange/start_peer_link/start_peer_link.usecase.dart';

/// Paramètres du [StartPeerLinkUsecase].
class StartPeerLinkParams extends Params {
  /// Crée des [StartPeerLinkParams].
  ///
  /// - [isPermissionRequested] : `true` pour demander les permissions à l'utilisateur, ce qui exige un écran ouvert.
  const StartPeerLinkParams({required this.isPermissionRequested});

  /// Indique si les permissions sont demandées à l'utilisateur.
  ///
  /// Une reprise automatique ne les demande pas : au démarrage, aucun écran n'est forcément là pour les afficher.
  final bool isPermissionRequested;
}
