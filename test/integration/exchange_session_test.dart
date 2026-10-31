import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:bedbug/application/exchange/exchange_session.dart';
import 'package:bedbug/application/exchange/exchange_stats_notifier.dart';
import 'package:bedbug/application/exchange/passive_exchange_notifier.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_reaction_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_seen_content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_storage_repository.dart';
import 'package:bedbug/features/content/infrastructure/models/content_hive_model.dart';
import 'package:bedbug/features/content/infrastructure/models/reaction_hive_model.dart';
import 'package:bedbug/features/content/infrastructure/models/storage_hive_model.dart';
import 'package:bedbug/features/exchange/domain/enums/exchange_frame_type.dart';
import 'package:bedbug/features/exchange/domain/gateways/exchange_frame_decoder_gateway.dart';
import 'package:bedbug/features/exchange/domain/gateways/exchange_transport_gateway.dart';
import 'package:bedbug/features/exchange/domain/gateways/peer_link_gateway.dart';
import 'package:bedbug/features/exchange/domain/object_values/exchange_bundle.dart';
import 'package:bedbug/features/exchange/domain/object_values/exchange_frame.dart';
import 'package:bedbug/features/exchange/domain/object_values/exchange_offer.dart';
import 'package:bedbug/features/exchange/domain/object_values/exchange_request.dart';
import 'package:bedbug/features/exchange/domain/usecases/build_exchange_bundle_usecase.dart';
import 'package:bedbug/features/exchange/domain/usecases/build_exchange_offer_usecase.dart';
import 'package:bedbug/features/exchange/domain/usecases/import_exchange_bundle_usecase.dart';
import 'package:bedbug/features/exchange/domain/usecases/select_from_exchange_offer_usecase.dart';
import 'package:bedbug/features/exchange/infrastructure/gateways/binary_exchange_frame_codec_gateway.dart';
import 'package:bedbug/features/exchange/infrastructure/gateways/binary_exchange_frame_decoder_gateway.dart';
import 'package:bedbug/features/exchange/infrastructure/gateways/ble_peer_link_gateway.dart';
import 'package:bedbug/features/exchange/infrastructure/gateways/json_zlib_exchange_codec_gateway.dart';
import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:bedbug/features/signature/domain/repositories/signature_repository.dart';
import 'package:bedbug/features/signature/infrastructure/datasources/hive_signature_repository.dart';
import 'package:bedbug/features/signature/infrastructure/models/signature_hive_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import '../helpers/hive_test_helper.dart';
import '../helpers/in_memory_exchange_transport_gateway.dart';

/// Codec utilisé pour fabriquer les messages d'un pair simulé.
const JsonZlibExchangeCodecGateway _codec = JsonZlibExchangeCodecGateway();

/// Codec utilisé pour fabriquer les trames d'un pair simulé.
const BinaryExchangeFrameCodecGateway _frameCodec = BinaryExchangeFrameCodecGateway();

/// Date de référence, dans le passé.
final DateTime _date = DateTime.fromMillisecondsSinceEpoch(1760000000000);

/// Retourne un contenu texte possédé par l'appareil.
///
/// - [id] : identifiant du contenu.
/// - [body] : corps du contenu.
TextContent _text(String id, {String body = 'Corps'}) {
  return TextContent(
    id: id,
    createdAt: _date,
    updatedAt: _date,
    signatureId: localSignatureId,
    origin: ContentOrigin.owned,
    broadcastScore: 1,
    survivalScore: 1,
    displayScore: 1,
    bounce: 0,
    sizeInBytes: 100,
    flair: 'france',
    title: 'Titre $id',
    body: body,
  );
}

/// Retourne un texte aléatoire de [length] caractères, qui se compresse mal.
///
/// - [random] : générateur aléatoire.
/// - [length] : longueur du texte.
String _noise(Random random, int length) {
  return String.fromCharCodes([for (var index = 0; index < length; index++) 33 + random.nextInt(90)]);
}

/// Ouvre les box d'un appareil simulé et retourne un conteneur qui les utilise.
///
/// Deux conteneurs ouverts avec des préfixes différents se comportent comme deux téléphones : les vrais use cases
/// et les vrais repositories, chacun sur sa propre base.
///
/// - [prefix] : préfixe des box de l'appareil.
/// - [overrides] : overrides supplémentaires.
Future<ProviderContainer> _openDevice(String prefix, {List<Override> overrides = const []}) async {
  final contents = await Hive.openBox<ContentHiveModel>('${prefix}_contents');
  final reactions = await Hive.openBox<ReactionHiveModel>('${prefix}_reactions');
  final seen = await Hive.openBox<int>('${prefix}_seen');
  final signatures = await Hive.openBox<SignatureHiveModel>('${prefix}_signatures');
  final storage = await Hive.openBox<StorageHiveModel>('${prefix}_storage');
  return ProviderContainer(
    overrides: [
      hiveContentBoxProvider.overrideWithValue(contents),
      hiveReactionBoxProvider.overrideWithValue(reactions),
      hiveSeenContentBoxProvider.overrideWithValue(seen),
      hiveSignatureBoxProvider.overrideWithValue(signatures),
      hiveStorageBoxProvider.overrideWithValue(storage),
      ...overrides,
    ],
  );
}

/// Retourne une session de l'appareil [device] sur [transport].
///
/// - [device] : conteneur de l'appareil.
/// - [transport] : connexion avec le pair.
/// - [inactivityTimeout] : durée sans progrès tolérée.
/// - [sessionTimeout] : durée maximale de la session.
ExchangeSession _session(
  ProviderContainer device,
  ExchangeTransportGateway transport, {
  Duration inactivityTimeout = const Duration(seconds: 5),
  Duration sessionTimeout = const Duration(seconds: 10),
}) {
  return ExchangeSession(
    transport,
    _frameCodec,
    device.read(buildExchangeOfferUsecaseProvider),
    device.read(selectFromExchangeOfferUsecaseProvider),
    device.read(buildExchangeBundleUsecaseProvider),
    device.read(importExchangeBundleUsecaseProvider),
    inactivityTimeout: inactivityTimeout,
    sessionTimeout: sessionTimeout,
  );
}

/// Fausse recherche de pairs : le test y fait arriver les connexions.
class _FakePeerLinkGateway implements PeerLinkGateway {
  /// Connexions livrées au reste de l'app.
  final StreamController<ExchangeTransportGateway> controller = StreamController.broadcast();

  @override
  Stream<ExchangeTransportGateway> get connections {
    return controller.stream;
  }

  @override
  Stream<void> get stopped {
    return const Stream.empty();
  }

  @override
  Future<bool> requestPermissions() async {
    return true;
  }

  @override
  Future<PeerLinkStartStatus> start() async {
    return PeerLinkStartStatus.started;
  }

  @override
  Future<void> stop() async {}

  /// Ferme le flux des connexions.
  Future<void> close() {
    return controller.close();
  }
}

/// Pair simulé, piloté trame par trame par le test, pour envoyer ce qu'un pair honnête n'enverrait jamais.
class _ScriptedPeer {
  /// Crée un [_ScriptedPeer] à l'écoute de [_transport].
  ///
  /// - [_transport] : extrémité de la connexion côté pair.
  _ScriptedPeer(this._transport) {
    _transport.incoming.listen((bytes) {
      for (final frame in _decoder.add(bytes)) {
        received.add(frame);
        _waiters.removeWhere((waiter) {
          if (waiter.type != frame.type) {
            return false;
          }
          waiter.completer.complete(frame);
          return true;
        });
      }
    });
  }

  /// Extrémité de la connexion côté pair.
  final InMemoryExchangeTransportGateway _transport;

  /// Reconstitue les trames de la session testée.
  final ExchangeFrameDecoderGateway _decoder = _frameCodec.createDecoder();

  /// Attentes de trames en cours.
  final List<({ExchangeFrameType type, Completer<ExchangeFrame> completer})> _waiters = [];

  /// Trames reçues de la session testée, dans l'ordre.
  final List<ExchangeFrame> received = [];

  /// Vrai si la session a reçu une trame de type [type].
  ///
  /// - [type] : type recherché.
  bool hasReceived(ExchangeFrameType type) {
    return received.any((frame) => frame.type == type);
  }

  /// Attend et retourne la première trame de type [type].
  ///
  /// - [type] : type attendu.
  Future<ExchangeFrame> waitFor(ExchangeFrameType type) {
    for (final frame in received) {
      if (frame.type == type) {
        return Future.value(frame);
      }
    }
    final completer = Completer<ExchangeFrame>();
    _waiters.add((type: type, completer: completer));
    return completer.future;
  }

  /// Envoie une trame à la session testée.
  ///
  /// - [type] : type de la trame.
  /// - [payload] : charge utile, vide par défaut.
  Future<void> send(ExchangeFrameType type, [Uint8List? payload]) {
    return _transport.send(_frameCodec.encode(ExchangeFrame(type, payload ?? Uint8List(0))));
  }

  /// Envoie un HELLO valide.
  Future<void> hello() {
    return send(ExchangeFrameType.hello, Uint8List.fromList([exchangeProtocolVersion]));
  }

  /// Déroule un échange honnête jusqu'à l'envoi du lot, où [contents] est livré à la session testée.
  ///
  /// - [contents] : contenus proposés puis envoyés.
  Future<void> deliver(List<TextContent> contents) async {
    await hello();
    final offered = [
      for (final content in contents)
        OfferedContent(id: content.id, sizeInBytes: 100, reactionCount: 0, latestReactionAt: null),
    ];
    await send(ExchangeFrameType.offer, _codec.encodeOffer(ExchangeOffer(contents: offered)));
    await waitFor(ExchangeFrameType.request);
    await send(
      ExchangeFrameType.request,
      _codec.encodeRequest(const ExchangeRequest(contentIds: [], reactionContentIds: [])),
    );
    final signature = Signature(id: '', createdAt: _date, updatedAt: _date, pseudo: 'bedbug', avatarText: '(◕‿◕)');
    final bundle = ExchangeBundle(
      contents: [for (final content in contents) ExchangedContent(content: content, signature: signature)],
      reactions: const [],
    );
    await send(ExchangeFrameType.data, _codec.encodeBundle(bundle));
  }
}

void main() {
  late Directory tempDir;
  late ProviderContainer deviceA;
  late ProviderContainer deviceB;
  late InMemoryExchangeTransportGateway transportA;
  late InMemoryExchangeTransportGateway transportB;

  setUp(() async {
    tempDir = await openTestHive();
    deviceA = await _openDevice('a');
    deviceB = await _openDevice('b');
    (transportA, transportB) = InMemoryExchangeTransportGateway.pair();
  });

  tearDown(() async {
    deviceA.dispose();
    deviceB.dispose();
    await closeTestHive(tempDir);
  });

  group('échange entre deux appareils', () {
    test('chaque appareil repart avec les contenus de l\'autre', () async {
      await deviceA.read(contentRepositoryProvider).addOne(_text('de-a'));
      await deviceB.read(contentRepositoryProvider).addOne(_text('de-b'));

      final results = await Future.wait([_session(deviceA, transportA).run(), _session(deviceB, transportB).run()]);

      expect(results.map((result) => result.failure), [null, null]);
      expect(results.map((result) => result.report?.importedContents), [1, 1]);
      final receivedByA = (await deviceA.read(contentRepositoryProvider).getByIds(['de-b'])).single;
      final receivedByB = (await deviceB.read(contentRepositoryProvider).getByIds(['de-a'])).single;
      expect(receivedByA.origin, ContentOrigin.public);
      expect(receivedByA.bounce, 1);
      expect((receivedByB as TextContent).title, 'Titre de-a');
      expect(transportA.isClosed, isTrue);
      expect(transportB.isClosed, isTrue);
      expect(transportA.isSuccessConfirmed, isTrue);
      expect(transportB.isSuccessConfirmed, isTrue);
    });

    test('deux appareils sans contenu terminent proprement l\'échange', () async {
      final results = await Future.wait([_session(deviceA, transportA).run(), _session(deviceB, transportB).run()]);

      expect(results.every((result) => result.isSuccess), isTrue);
      expect(results.map((result) => result.report?.importedContents), [0, 0]);
    });

    test('les lots se croisent quand les deux envois dépassent un morceau du transport', () async {
      // Texte peu compressible : le lot dépasse largement exchangeChunkBytes des deux côtés à la fois.
      final random = Random(1);
      for (var index = 0; index < 5; index++) {
        await deviceA.read(contentRepositoryProvider).addOne(_text('a-$index', body: _noise(random, 4000)));
        await deviceB.read(contentRepositoryProvider).addOne(_text('b-$index', body: _noise(random, 4000)));
      }

      final results = await Future.wait([_session(deviceA, transportA).run(), _session(deviceB, transportB).run()]);

      expect(results.map((result) => result.failure), [null, null]);
      expect(results.map((result) => result.report?.importedContents), [5, 5]);
    });

    test('un second échange ne retransfère rien', () async {
      await deviceA.read(contentRepositoryProvider).addOne(_text('de-a'));
      await Future.wait([_session(deviceA, transportA).run(), _session(deviceB, transportB).run()]);

      final (secondA, secondB) = InMemoryExchangeTransportGateway.pair();
      final results = await Future.wait([_session(deviceA, secondA).run(), _session(deviceB, secondB).run()]);

      expect(results.map((result) => result.report?.importedContents), [0, 0]);
    });
  });

  group('pair qui ne suit pas le protocole', () {
    test('une autre version arrête l\'échange avant toute lecture de la base', () async {
      final peer = _ScriptedPeer(transportB);
      final session = _session(deviceA, transportA).run();

      await peer.send(ExchangeFrameType.hello, Uint8List.fromList([exchangeProtocolVersion + 1]));

      expect((await session).failure, ExchangeSessionFailure.incompatibleVersion);
      expect(peer.hasReceived(ExchangeFrameType.offer), isFalse);
    });

    test('une trame hors séquence est une violation, et le pair en est prévenu', () async {
      final peer = _ScriptedPeer(transportB);
      final session = _session(deviceA, transportA).run();

      await peer.send(ExchangeFrameType.data, Uint8List.fromList([1, 2, 3]));

      expect((await session).failure, ExchangeSessionFailure.protocolViolation);
      expect(peer.hasReceived(ExchangeFrameType.error), isTrue);
    });

    test('un DONE avant le lot n\'est pas pris pour une fin d\'échange', () async {
      final peer = _ScriptedPeer(transportB);
      final session = _session(deviceA, transportA).run();

      await peer.hello();
      await peer.send(ExchangeFrameType.done);

      expect((await session).failure, ExchangeSessionFailure.protocolViolation);
    });

    test('des octets sans rapport sont une violation', () async {
      final session = _session(deviceA, transportA).run();

      await transportB.send(Uint8List.fromList([0x7F, 1, 2, 3, 4, 5]));

      expect((await session).failure, ExchangeSessionFailure.protocolViolation);
    });

    test('une offre illisible est une violation', () async {
      final peer = _ScriptedPeer(transportB);
      final session = _session(deviceA, transportA).run();

      await peer.hello();
      await peer.send(ExchangeFrameType.offer, Uint8List.fromList([1, 2, 3]));

      expect((await session).failure, ExchangeSessionFailure.protocolViolation);
    });

    test('un contenu non demandé n\'est pas importé', () async {
      final peer = _ScriptedPeer(transportB);
      final session = _session(deviceA, transportA).run();

      await peer.hello();
      await peer.send(ExchangeFrameType.offer, _codec.encodeOffer(const ExchangeOffer(contents: [])));
      await peer.waitFor(ExchangeFrameType.request);
      await peer.send(
        ExchangeFrameType.request,
        _codec.encodeRequest(const ExchangeRequest(contentIds: [], reactionContentIds: [])),
      );
      final bundle = ExchangeBundle(
        contents: [ExchangedContent(content: _text('poussé'), signature: null)],
        reactions: const [],
      );
      await peer.send(ExchangeFrameType.data, _codec.encodeBundle(bundle));
      await peer.send(ExchangeFrameType.done);

      final result = await session;
      expect(result.isSuccess, isTrue);
      expect(result.report?.importedContents, 0);
      expect(await deviceA.read(contentRepositoryProvider).getByIds(['poussé']), isEmpty);
    });

    test('un lot trop gros pour la trame n\'est pas envoyé', () async {
      final random = Random(2);
      final ids = [for (var index = 0; index < 30; index++) 'lourd-$index'];
      for (final id in ids) {
        await deviceA.read(contentRepositoryProvider).addOne(_text(id, body: _noise(random, 60000)));
      }
      final peer = _ScriptedPeer(transportB);
      final session = _session(deviceA, transportA).run();

      await peer.hello();
      await peer.send(ExchangeFrameType.offer, _codec.encodeOffer(const ExchangeOffer(contents: [])));
      await peer.waitFor(ExchangeFrameType.request);
      await peer.send(
        ExchangeFrameType.request,
        _codec.encodeRequest(ExchangeRequest(contentIds: ids, reactionContentIds: const [])),
      );

      expect((await session).failure, ExchangeSessionFailure.localError);
      expect(peer.hasReceived(ExchangeFrameType.data), isFalse);
      expect(peer.hasReceived(ExchangeFrameType.error), isTrue);
    });

    test('l\'abandon du pair termine la session', () async {
      final peer = _ScriptedPeer(transportB);
      final session = _session(deviceA, transportA).run();

      await peer.send(ExchangeFrameType.error);

      expect((await session).failure, ExchangeSessionFailure.peerError);
    });
  });

  group('connexion', () {
    test('une connexion perdue avant le lot est un échec', () async {
      final peer = _ScriptedPeer(transportB);
      final session = _session(deviceA, transportA).run();

      await peer.hello();
      await transportB.close();

      expect((await session).failure, ExchangeSessionFailure.transportClosed);
      expect(transportA.isSuccessConfirmed, isFalse);
    });

    test('une connexion perdue une fois le lot importé n\'est pas un échec', () async {
      final peer = _ScriptedPeer(transportB);
      final session = _session(deviceA, transportA).run();

      await peer.deliver([_text('livré')]);
      await peer.waitFor(ExchangeFrameType.done);
      await transportB.close();

      final result = await session;
      expect(result.isSuccess, isTrue);
      expect(result.report?.importedContents, 1);
    });

    test('un lot suivi aussitôt de la fermeture est quand même traité', () async {
      final peer = _ScriptedPeer(transportB);
      final session = _session(deviceA, transportA).run();

      await peer.hello();
      await peer.send(ExchangeFrameType.offer, _codec.encodeOffer(const ExchangeOffer(contents: [])));
      await peer.waitFor(ExchangeFrameType.request);
      await peer.send(
        ExchangeFrameType.request,
        _codec.encodeRequest(const ExchangeRequest(contentIds: [], reactionContentIds: [])),
      );
      await peer.send(ExchangeFrameType.data, _codec.encodeBundle(const ExchangeBundle(contents: [], reactions: [])));
      await transportB.close();

      final result = await session;
      expect(result.isSuccess, isTrue);
      expect(result.report, isNotNull);
    });

    test('un pair muet est abandonné au bout du délai d\'inactivité', () async {
      _ScriptedPeer(transportB);

      final result = await _session(deviceA, transportA, inactivityTimeout: const Duration(milliseconds: 50)).run();

      expect(result.failure, ExchangeSessionFailure.timeout);
      expect(transportA.isClosed, isTrue);
    });

    test('un pair qui envoie au compte-gouttes est coupé par la durée maximale', () async {
      final peer = _ScriptedPeer(transportB);
      final session = _session(
        deviceA,
        transportA,
        inactivityTimeout: const Duration(milliseconds: 100),
        sessionTimeout: const Duration(milliseconds: 150),
      ).run();

      await peer.hello();
      // Une offre annoncée en entier, mais dont les octets arrivent un par un : le pair n'est jamais inactif.
      final frame = ExchangeFrame(ExchangeFrameType.offer, Uint8List(1000));
      await transportB.send(_frameCodec.encode(frame).sublist(0, exchangeFrameHeaderBytes));
      final drip = Timer.periodic(const Duration(milliseconds: 20), (timer) {
        if (!transportB.isClosed) {
          unawaited(transportB.send(Uint8List(1)));
        }
      });
      final result = await session;
      drip.cancel();

      expect(result.failure, ExchangeSessionFailure.timeout);
    });

    test('un envoi bloqué par la radio ne bloque pas la session', () async {
      _ScriptedPeer(transportB);
      transportA.isSendBlocked = true;

      final result = await _session(deviceA, transportA, inactivityTimeout: const Duration(milliseconds: 50)).run();

      expect(result.failure, ExchangeSessionFailure.timeout);
    });
  });

  group('transfert passif', () {
    test('une connexion reçue déroule une session, et les compteurs reflètent son bilan', () async {
      final gateway = _FakePeerLinkGateway();
      addTearDown(gateway.close);
      final passiveDevice = await _openDevice('c', overrides: [peerLinkGatewayProvider.overrideWithValue(gateway)]);
      addTearDown(passiveDevice.dispose);
      await deviceB.read(contentRepositoryProvider).addOne(_text('de-b'));
      await passiveDevice.read(passiveExchangeNotifierProvider.future);

      gateway.controller.add(transportA);
      await _session(deviceB, transportB).run();
      while (passiveDevice.read(exchangeStatsNotifierProvider).successCount == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      final stats = passiveDevice.read(exchangeStatsNotifierProvider);
      expect(stats.failureCount, 0);
      expect(stats.contentCount, 1);
    });
  });

  group('annulation', () {
    test('cancel ferme la connexion et prévient le pair', () async {
      final peer = _ScriptedPeer(transportB);
      final session = _session(deviceA, transportA);
      final result = session.run();

      await peer.waitFor(ExchangeFrameType.hello);
      await session.cancel();

      expect((await result).failure, ExchangeSessionFailure.cancelled);
      expect(peer.hasReceived(ExchangeFrameType.error), isTrue);
      expect(transportA.isClosed, isTrue);
    });

    test('cancel pendant un envoi bloqué répond quand même', () async {
      _ScriptedPeer(transportB);
      transportA.isSendBlocked = true;
      final session = _session(deviceA, transportA);
      final result = session.run();

      await Future<void>.delayed(Duration.zero);
      await session.cancel();

      expect((await result).failure, ExchangeSessionFailure.cancelled);
    });

    test('annuler une session terminée ne change pas son résultat', () async {
      final session = _session(deviceA, transportA);
      final results = await Future.wait([session.run(), _session(deviceB, transportB).run()]);

      await session.cancel();

      expect(results.first.isSuccess, isTrue);
    });
  });
}
