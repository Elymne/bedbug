import 'dart:async';

import 'package:bedbug/features/exchange/domain/gateways/exchange_transport_gateway.dart';
import 'package:flutter/services.dart';

/// Implémentation de [ExchangeTransportGateway] sur une connexion BLE tenue par le code Kotlin.
///
/// Le socket vit côté Android, sur ses propres threads : cette classe n'en est que la représentation Dart. Les octets
/// reçus lui sont confiés par `BlePeerLinkGateway`, qui écoute les événements de toutes les connexions.
class BleExchangeTransportGateway implements ExchangeTransportGateway {
  /// Crée un [BleExchangeTransportGateway].
  ///
  /// - [_id] : identifiant de la connexion côté Android.
  /// - [_channel] : canal des appels vers Android.
  BleExchangeTransportGateway(this._id, this._channel);

  /// Identifiant de la connexion côté Android.
  final int _id;

  /// Canal des appels vers Android.
  final MethodChannel _channel;

  /// Octets reçus du pair.
  final StreamController<Uint8List> _incoming = StreamController();

  @override
  Stream<Uint8List> get incoming {
    return _incoming.stream;
  }

  @override
  Future<void> send(Uint8List bytes) {
    return _channel.invokeMethod<void>('send', {'id': _id, 'bytes': bytes});
  }

  @override
  Future<void> confirmSuccess() {
    return _channel.invokeMethod<void>('confirm', {'id': _id});
  }

  @override
  Future<void> close() {
    return _channel.invokeMethod<void>('close', {'id': _id});
  }

  /// Transmet [bytes], reçus d'Android, à celui qui écoute [incoming].
  ///
  /// - [bytes] : octets reçus du pair.
  void addReceived(Uint8List bytes) {
    if (!_incoming.isClosed) {
      _incoming.add(bytes);
    }
  }

  /// Termine [incoming] : Android a fermé la connexion.
  void markClosed() {
    // Sans attendre : le `Future` de `close` ne se termine jamais si personne n'écoute.
    unawaited(_incoming.close());
  }
}
