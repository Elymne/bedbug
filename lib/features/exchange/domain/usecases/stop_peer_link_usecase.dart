import 'package:bedbug/features/exchange/domain/gateways/peer_link_gateway.dart';
import 'package:bedbug/features/exchange/infrastructure/gateways/ble_peer_link_gateway.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [StopPeerLinkUsecase].
final stopPeerLinkUsecaseProvider = Provider<StopPeerLinkUsecase>((ref) {
  return StopPeerLinkUsecase(ref.read(peerLinkGatewayProvider));
});

/// Arrête la recherche de téléphones proches.
///
/// L'échange tourne en arrière-plan et consomme de la batterie : l'utilisateur doit pouvoir le couper à tout moment.
class StopPeerLinkUsecase extends Usecase<NoParams, StopPeerLinkFailure, void> {
  /// Crée un [StopPeerLinkUsecase].
  StopPeerLinkUsecase(this._peerLinkGateway);

  final PeerLinkGateway _peerLinkGateway;

  @override
  Future<Either<StopPeerLinkFailure, void>> call(NoParams params) async {
    try {
      await _peerLinkGateway.stop();
      return const Right(null);
    } catch (error, stackTrace) {
      AppLogger.error('StopPeerLinkUsecase', error, stackTrace);
      return const Left(StopPeerLinkFailure.unavailable);
    }
  }
}

/// Échecs possibles du [StopPeerLinkUsecase].
enum StopPeerLinkFailure {
  /// Le service d'échange n'a pas répondu.
  unavailable,
}
