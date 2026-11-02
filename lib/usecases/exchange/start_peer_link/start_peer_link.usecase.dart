import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/gateways/exchange/peer_link.gateway.ble.dart';
import 'package:bedbug/gateways/exchange/peer_link.gateway.dart';
import 'package:bedbug/resources/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log.repository.hive.dart';
import 'package:bedbug/usecases/exchange/start_peer_link/start_peer_link.failure.dart';
import 'package:bedbug/usecases/exchange/start_peer_link/start_peer_link.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [StartPeerLinkUsecase].
final startPeerLinkUsecaseProvider = Provider<StartPeerLinkUsecase>((ref) {
  return StartPeerLinkUsecase(ref.read(peerLinkGatewayProvider), ref.read(errorLogRepositoryProvider));
});

/// Démarre la recherche de téléphones proches, après avoir obtenu les permissions.
///
/// Les contenus ne circulent que si des téléphones se rencontrent : c'est le point d'entrée du transfert passif. Il
/// distingue les causes d'échec parce que chacune appelle une réaction différente de l'utilisateur.
class StartPeerLinkUsecase extends Usecase<StartPeerLinkParams, StartPeerLinkFailure, void> {
  /// Crée un [StartPeerLinkUsecase].
  StartPeerLinkUsecase(this._peerLinkGateway, this._errorLogRepository);

  final PeerLinkGateway _peerLinkGateway;
  final ErrorLogRepository _errorLogRepository;

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
      await _errorLogRepository.record(source: 'StartPeerLinkUsecase', error: error, stackTrace: stackTrace);
      return const Left(StartPeerLinkFailure.unavailable);
    }
  }
}
