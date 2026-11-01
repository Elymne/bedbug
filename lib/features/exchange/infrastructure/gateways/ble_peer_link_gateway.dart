import 'dart:async';

import 'package:bedbug/features/exchange/domain/enums/exchange_log_outcome.dart';
import 'package:bedbug/features/exchange/domain/gateways/exchange_transport_gateway.dart';
import 'package:bedbug/features/exchange/domain/gateways/peer_link_gateway.dart';
import 'package:bedbug/features/exchange/domain/object_values/peer_attempt.dart';
import 'package:bedbug/features/exchange/infrastructure/gateways/ble_exchange_transport_gateway.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Canal des appels vers le service d'échange Android.
const MethodChannel exchangeMethodChannel = MethodChannel('bedbug/exchange');

/// Canal des événements du service d'échange Android.
const EventChannel exchangeEventChannel = EventChannel('bedbug/exchange/events');

/// Canal de la demande de permissions, tenu par l'activité Android.
const MethodChannel exchangePermissionsChannel = MethodChannel('bedbug/exchange/permissions');

/// Provider du [BlePeerLinkGateway].
final peerLinkGatewayProvider = Provider<PeerLinkGateway>((ref) => BlePeerLinkGateway());

/// Implémentation de [PeerLinkGateway] sur le service d'échange Android (annonce et scan BLE, canaux L2CAP).
///
/// Le fonctionnement côté Android est expliqué dans `documentations/exchange/README.md`.
class BlePeerLinkGateway implements PeerLinkGateway {
  /// Crée un [BlePeerLinkGateway].
  BlePeerLinkGateway();

  /// Connexions établies avec des pairs.
  final StreamController<ExchangeTransportGateway> _connections = StreamController.broadcast();

  /// Pairs vus sans échange.
  final StreamController<PeerAttempt> _attempts = StreamController.broadcast();

  /// Arrêts de la recherche.
  final StreamController<void> _stopped = StreamController.broadcast();

  /// Connexions ouvertes, par identifiant Android.
  final Map<int, BleExchangeTransportGateway> _transports = {};

  /// Vrai une fois les événements Android écoutés : l'abonnement dure autant que l'app.
  bool _isListening = false;

  @override
  Stream<ExchangeTransportGateway> get connections {
    return _connections.stream;
  }

  @override
  Stream<PeerAttempt> get attempts {
    return _attempts.stream;
  }

  @override
  Stream<void> get stopped {
    return _stopped.stream;
  }

  @override
  Future<bool> requestPermissions() async {
    return await exchangePermissionsChannel.invokeMethod<bool>('request') ?? false;
  }

  @override
  Future<PeerLinkStartStatus> start() async {
    // Avant `start` : Android ferme toute connexion qu'aucun code Dart n'écoute.
    if (!_isListening) {
      _isListening = true;
      exchangeEventChannel.receiveBroadcastStream().listen(_onEvent);
    }
    final status = await exchangeMethodChannel.invokeMethod<String>('start');
    return switch (status) {
      'started' => PeerLinkStartStatus.started,
      'bluetoothOff' => PeerLinkStartStatus.bluetoothOff,
      'permissionDenied' => PeerLinkStartStatus.permissionDenied,
      _ => PeerLinkStartStatus.unavailable,
    };
  }

  @override
  Future<void> stop() {
    return exchangeMethodChannel.invokeMethod<void>('stop');
  }

  /// Aiguille un événement Android vers la bonne connexion.
  ///
  /// - [rawEvent] : événement reçu, de la forme `{event, id?, bytes?, peer?, isInitiator?}`.
  void _onEvent(dynamic rawEvent) {
    final event = rawEvent as Map<Object?, Object?>;
    final id = event['id'] as int?;
    switch (event['event']) {
      case 'connected':
        final transport = BleExchangeTransportGateway(
          id!,
          exchangeMethodChannel,
          peerAddress: event['peer']! as String,
          isInitiator: event['isInitiator']! as bool,
        );
        _transports[id] = transport;
        _connections.add(transport);
      case 'data':
        _transports[id]?.addReceived(event['bytes']! as Uint8List);
      case 'closed':
        _transports.remove(id)?.markClosed();
      case 'connectionFailed':
        _attempts.add(PeerAttempt(peerAddress: event['peer']! as String, outcome: ExchangeLogOutcome.connectionFailed));
      case 'peerDelayed':
        _attempts.add(PeerAttempt(peerAddress: event['peer']! as String, outcome: ExchangeLogOutcome.peerDelayed));
      case 'stopped':
        _stopped.add(null);
    }
  }
}
