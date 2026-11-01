import 'dart:async';

import 'package:bedbug/features/exchange/domain/gateways/exchange_transport_gateway.dart';
import 'package:bedbug/features/exchange/domain/gateways/peer_link_gateway.dart';
import 'package:bedbug/features/exchange/infrastructure/gateways/ble_peer_link_gateway.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> calls;
  late MockStreamHandlerEventSink events;
  late String startStatus;

  setUp(() {
    calls = [];
    startStatus = 'started';
    messenger.setMockMethodCallHandler(exchangeMethodChannel, (call) async {
      calls.add(call);
      return call.method == 'start' ? startStatus : null;
    });
    messenger.setMockStreamHandler(
      exchangeEventChannel,
      MockStreamHandler.inline(onListen: (_, sink) => events = sink),
    );
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(exchangeMethodChannel, null);
    messenger.setMockStreamHandler(exchangeEventChannel, null);
  });

  test('traduit le statut de démarrage d\'Android', () async {
    final gateway = BlePeerLinkGateway();

    expect(await gateway.start(), PeerLinkStartStatus.started);
    startStatus = 'bluetoothOff';
    expect(await gateway.start(), PeerLinkStartStatus.bluetoothOff);
    startStatus = 'unavailable';
    expect(await gateway.start(), PeerLinkStartStatus.unavailable);
  });

  test('une connexion livre ses octets dans l\'ordre, puis se termine à la fermeture', () async {
    final gateway = BlePeerLinkGateway();
    final connections = <ExchangeTransportGateway>[];
    gateway.connections.listen(connections.add);
    await gateway.start();

    events.success({'event': 'connected', 'id': 7, 'peer': 'AA:BB', 'isInitiator': true});
    await Future<void>.delayed(Duration.zero);
    final received = <int>[];
    final isDone = Completer<void>();
    connections.single.incoming.listen(received.addAll, onDone: isDone.complete);
    events.success({
      'event': 'data',
      'id': 7,
      'bytes': Uint8List.fromList([1, 2]),
    });
    events.success({
      'event': 'data',
      'id': 7,
      'bytes': Uint8List.fromList([3]),
    });
    events.success({'event': 'closed', 'id': 7});
    await isDone.future;

    expect(received, [1, 2, 3]);
  });

  test('sépare les octets de deux connexions', () async {
    final gateway = BlePeerLinkGateway();
    final connections = <ExchangeTransportGateway>[];
    gateway.connections.listen(connections.add);
    await gateway.start();

    events.success({'event': 'connected', 'id': 1, 'peer': 'AA:BB', 'isInitiator': true});
    events.success({'event': 'connected', 'id': 2, 'peer': 'AA:BB', 'isInitiator': true});
    await Future<void>.delayed(Duration.zero);
    final first = <int>[];
    connections.first.incoming.listen(first.addAll);
    events.success({
      'event': 'data',
      'id': 2,
      'bytes': Uint8List.fromList([9]),
    });
    await Future<void>.delayed(Duration.zero);

    expect(first, isEmpty);
  });

  test('l\'envoi et la fermeture visent la bonne connexion', () async {
    final gateway = BlePeerLinkGateway();
    final connections = <ExchangeTransportGateway>[];
    gateway.connections.listen(connections.add);
    await gateway.start();
    events.success({'event': 'connected', 'id': 3, 'peer': 'AA:BB', 'isInitiator': true});
    await Future<void>.delayed(Duration.zero);

    await connections.single.send(Uint8List.fromList([5]));
    await connections.single.close();

    expect(calls.last.method, 'close');
    expect(calls.last.arguments, {'id': 3});
    final send = calls[calls.length - 2];
    expect(send.method, 'send');
    expect((send.arguments as Map<Object?, Object?>)['bytes'], [5]);
  });

  test('la confirmation de réussite vise la bonne connexion', () async {
    final gateway = BlePeerLinkGateway();
    final connections = <ExchangeTransportGateway>[];
    gateway.connections.listen(connections.add);
    await gateway.start();
    events.success({'event': 'connected', 'id': 5, 'peer': 'AA:BB', 'isInitiator': true});
    await Future<void>.delayed(Duration.zero);

    await connections.single.confirmSuccess();

    expect(calls.last.method, 'confirm');
    expect(calls.last.arguments, {'id': 5});
  });

  test('un envoi refusé par Android remonte en exception, pour que la session s\'arrête', () async {
    final gateway = BlePeerLinkGateway();
    final connections = <ExchangeTransportGateway>[];
    gateway.connections.listen(connections.add);
    await gateway.start();
    events.success({'event': 'connected', 'id': 4, 'peer': 'AA:BB', 'isInitiator': true});
    await Future<void>.delayed(Duration.zero);
    messenger.setMockMethodCallHandler(exchangeMethodChannel, (call) async {
      throw PlatformException(code: 'closed');
    });

    await expectLater(connections.single.send(Uint8List(1)), throwsA(isA<PlatformException>()));
  });

  test('signale un arrêt venu d\'Android, comme le bouton de la notification', () async {
    final gateway = BlePeerLinkGateway();
    var stopCount = 0;
    gateway.stopped.listen((_) => stopCount++);
    await gateway.start();

    events.success({'event': 'stopped'});
    await Future<void>.delayed(Duration.zero);

    expect(stopCount, 1);
  });
}
