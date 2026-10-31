import 'package:bedbug/features/exchange/domain/gateways/peer_link_gateway.dart';
import 'package:bedbug/features/exchange/infrastructure/gateways/ble_peer_link_gateway.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [StartPeerLinkUsecase].
final startPeerLinkUsecaseProvider = Provider<StartPeerLinkUsecase>((ref) {
  return StartPeerLinkUsecase(ref.read(peerLinkGatewayProvider));
});

/// Démarre la recherche de téléphones proches, après avoir obtenu les permissions.
///
/// Les contenus ne circulent que si des téléphones se rencontrent : c'est le point d'entrée du transfert passif. Il
/// distingue les causes d'échec parce que chacune appelle une réaction différente de l'utilisateur.
class StartPeerLinkUsecase extends Usecase<StartPeerLinkParams, StartPeerLinkFailure, void> {
  /// Crée un [StartPeerLinkUsecase].
  StartPeerLinkUsecase(this._peerLinkGateway);

  final PeerLinkGateway _peerLinkGateway;

  @override
  Future<Either<StartPeerLinkFailure, void>> call(StartPeerLinkParams params) async {
    try {
      if (params.isPermissionRequested && !await _peerLinkGateway.requestPermissions()) {
        return const Left(StartPeerLinkFailure.permissionDenied);
      }
      return switch (await _peerLinkGateway.start()) {
        PeerLinkStartStatus.started => const Right(null),
        PeerLinkStartStatus.bluetoothOff => const Left(StartPeerLinkFailure.bluetoothOff),
        PeerLinkStartStatus.permissionDenied => const Left(StartPeerLinkFailure.permissionDenied),
        PeerLinkStartStatus.unavailable => const Left(StartPeerLinkFailure.unavailable),
      };
    } catch (error, stackTrace) {
      AppLogger.error('StartPeerLinkUsecase', error, stackTrace);
      return const Left(StartPeerLinkFailure.unavailable);
    }
  }
}

/// Échecs possibles du [StartPeerLinkUsecase].
enum StartPeerLinkFailure {
  /// L'utilisateur a refusé les permissions.
  permissionDenied,

  /// Le Bluetooth du téléphone est désactivé.
  bluetoothOff,

  /// Le téléphone ne permet pas la recherche de pairs, ou Android l'a refusée.
  unavailable,
}

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
