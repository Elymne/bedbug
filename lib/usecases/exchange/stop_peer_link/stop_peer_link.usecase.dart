import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/gateways/exchange/peer_link.gateway.ble.dart';
import 'package:bedbug/gateways/exchange/peer_link.gateway.dart';
import 'package:bedbug/usecases/exchange/stop_peer_link/stop_peer_link.failure.dart';
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
