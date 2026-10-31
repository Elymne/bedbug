import 'dart:async';
import 'dart:typed_data';

import 'package:bedbug/features/exchange/domain/gateways/exchange_transport_gateway.dart';

/// Transport en mémoire : relie deux extrémités sans radio, pour tester le protocole de session.
class InMemoryExchangeTransportGateway implements ExchangeTransportGateway {
  /// Crée une extrémité non reliée. Utiliser [pair] pour obtenir deux extrémités connectées.
  InMemoryExchangeTransportGateway._();

  /// Retourne deux extrémités connectées l'une à l'autre.
  static (InMemoryExchangeTransportGateway, InMemoryExchangeTransportGateway) pair() {
    final first = InMemoryExchangeTransportGateway._();
    final second = InMemoryExchangeTransportGateway._();
    first._peer = second;
    second._peer = first;
    return (first, second);
  }

  /// Extrémité opposée.
  late final InMemoryExchangeTransportGateway _peer;

  /// Octets reçus de l'extrémité opposée.
  final StreamController<Uint8List> _incoming = StreamController();

  /// Vrai si les envois ne se terminent jamais, comme une radio saturée.
  bool isSendBlocked = false;

  /// Vrai une fois la connexion fermée.
  bool get isClosed {
    return _incoming.isClosed;
  }

  @override
  Stream<Uint8List> get incoming {
    return _incoming.stream;
  }

  @override
  Future<void> send(Uint8List bytes) async {
    if (isSendBlocked) {
      await Completer<void>().future;
    }
    if (isClosed) {
      throw StateError('connexion fermée');
    }
    // Laisse la main à l'autre extrémité, comme une vraie radio qui envoie pendant que l'on reçoit.
    await Future<void>.delayed(Duration.zero);
    if (!_peer.isClosed) {
      _peer._incoming.add(Uint8List.fromList(bytes));
    }
  }

  @override
  Future<void> close() async {
    if (isClosed) {
      return;
    }
    // Sans attendre : le `Future` de `close` ne se termine jamais si personne n'écoute cette extrémité.
    unawaited(_incoming.close());
    unawaited(_peer.close());
  }
}
