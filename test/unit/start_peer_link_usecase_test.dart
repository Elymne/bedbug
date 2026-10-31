import 'package:bedbug/features/exchange/domain/gateways/exchange_transport_gateway.dart';
import 'package:bedbug/features/exchange/domain/gateways/peer_link_gateway.dart';
import 'package:bedbug/features/exchange/domain/usecases/start_peer_link_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fausse recherche de pairs, dont les réponses sont fixées par le test.
class _FakePeerLinkGateway implements PeerLinkGateway {
  _FakePeerLinkGateway({this.isPermissionGranted = true, this.status = PeerLinkStartStatus.started, this.error});

  /// Réponse à la demande de permissions.
  final bool isPermissionGranted;

  /// Statut de démarrage.
  final PeerLinkStartStatus status;

  /// Erreur levée au démarrage, `null` pour ne pas en lever.
  final Object? error;

  /// Nombre d'appels à [start].
  int startCount = 0;

  @override
  Stream<ExchangeTransportGateway> get connections {
    return const Stream.empty();
  }

  @override
  Stream<void> get stopped {
    return const Stream.empty();
  }

  @override
  Future<bool> requestPermissions() async {
    return isPermissionGranted;
  }

  @override
  Future<PeerLinkStartStatus> start() async {
    startCount++;
    final error = this.error;
    if (error != null) {
      throw error;
    }
    return status;
  }

  @override
  Future<void> stop() async {}
}

/// Paramètres d'un démarrage demandé par l'utilisateur.
const StartPeerLinkParams _params = StartPeerLinkParams(isPermissionRequested: true);

void main() {
  test('une reprise automatique ne demande pas les permissions et respecte le refus d\'Android', () async {
    final gateway = _FakePeerLinkGateway(isPermissionGranted: false, status: PeerLinkStartStatus.permissionDenied);

    final result = await StartPeerLinkUsecase(gateway)(const StartPeerLinkParams(isPermissionRequested: false));

    expect(result.left, StartPeerLinkFailure.permissionDenied);
    expect(gateway.startCount, 1);
  });

  test('démarre une fois les permissions accordées', () async {
    final gateway = _FakePeerLinkGateway();

    final result = await StartPeerLinkUsecase(gateway)(_params);

    expect(result.isSuccess, isTrue);
    expect(gateway.startCount, 1);
  });

  test('ne touche pas à la radio sans les permissions', () async {
    final gateway = _FakePeerLinkGateway(isPermissionGranted: false);

    final result = await StartPeerLinkUsecase(gateway)(_params);

    expect(result.left, StartPeerLinkFailure.permissionDenied);
    expect(gateway.startCount, 0);
  });

  test('distingue le Bluetooth coupé d\'un téléphone incompatible', () async {
    final off = _FakePeerLinkGateway(status: PeerLinkStartStatus.bluetoothOff);
    final unavailable = _FakePeerLinkGateway(status: PeerLinkStartStatus.unavailable);

    expect((await StartPeerLinkUsecase(off)(_params)).left, StartPeerLinkFailure.bluetoothOff);
    expect((await StartPeerLinkUsecase(unavailable)(_params)).left, StartPeerLinkFailure.unavailable);
  });

  test('une erreur du service devient un échec typé', () async {
    final gateway = _FakePeerLinkGateway(error: StateError('canal indisponible'));

    expect((await StartPeerLinkUsecase(gateway)(_params)).left, StartPeerLinkFailure.unavailable);
  });
}
