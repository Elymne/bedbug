import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:bedbug/application/exchange/exchange_session.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/reaction.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/usecases/delete_own_content_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/get_storage_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/save_content_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/save_reaction_usecase.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_reaction_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_seen_content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_storage_repository.dart';
import 'package:bedbug/features/content/infrastructure/models/content_hive_model.dart';
import 'package:bedbug/features/content/infrastructure/models/reaction_hive_model.dart';
import 'package:bedbug/features/content/infrastructure/models/storage_hive_model.dart';
import 'package:bedbug/features/exchange/domain/gateways/exchange_transport_gateway.dart';
import 'package:bedbug/features/exchange/domain/usecases/build_exchange_bundle_usecase.dart';
import 'package:bedbug/features/exchange/domain/usecases/build_exchange_offer_usecase.dart';
import 'package:bedbug/features/exchange/domain/usecases/import_exchange_bundle_usecase.dart';
import 'package:bedbug/features/exchange/domain/usecases/select_from_exchange_offer_usecase.dart';
import 'package:bedbug/features/exchange/infrastructure/gateways/binary_exchange_frame_codec_gateway.dart';
import 'package:bedbug/features/signature/domain/repositories/signature_repository.dart';
import 'package:bedbug/features/signature/infrastructure/datasources/hive_signature_repository.dart';
import 'package:bedbug/features/signature/infrastructure/models/signature_hive_model.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import '../helpers/hive_test_helper.dart';
import '../helpers/in_memory_exchange_transport_gateway.dart';

/// Nombre d'appareils du réseau simulé.
const int _deviceCount = 10;

/// Date de référence, dans le passé.
final DateTime _date = DateTime.fromMillisecondsSinceEpoch(1760000000000);

/// Transport qui se coupe après [_remainingSends] envois, comme deux téléphones qui s'éloignent.
class _CuttingTransport implements ExchangeTransportGateway {
  /// Crée un [_CuttingTransport].
  ///
  /// - [_inner] : transport réel.
  /// - [_remainingSends] : nombre d'envois avant la coupure.
  _CuttingTransport(this._inner, this._remainingSends);

  /// Transport réel.
  final InMemoryExchangeTransportGateway _inner;

  /// Nombre d'envois avant la coupure.
  int _remainingSends;

  @override
  Stream<Uint8List> get incoming {
    return _inner.incoming;
  }

  @override
  Future<void> send(Uint8List bytes) async {
    if (_remainingSends <= 0) {
      await _inner.close();
      throw StateError('connexion perdue');
    }
    _remainingSends--;
    await _inner.send(bytes);
  }

  @override
  Future<void> confirmSuccess() {
    return _inner.confirmSuccess();
  }

  @override
  Future<void> close() {
    return _inner.close();
  }
}

/// Un téléphone simulé : les vrais use cases et les vrais repositories, sur ses propres box Hive.
class _Device {
  /// Crée un [_Device].
  ///
  /// - [name] : nom de l'appareil, préfixe de ses box et de ses contenus.
  /// - [container] : conteneur Riverpod de l'appareil.
  _Device(this.name, this.container);

  /// Nom de l'appareil.
  final String name;

  /// Conteneur Riverpod de l'appareil.
  final ProviderContainer container;

  /// Nombre de contenus publiés.
  int _publishedCount = 0;

  /// Ouvre les box d'un appareil.
  ///
  /// - [name] : nom de l'appareil.
  static Future<_Device> open(String name) async {
    final contents = await Hive.openBox<ContentHiveModel>('${name}_contents');
    final reactions = await Hive.openBox<ReactionHiveModel>('${name}_reactions');
    final seen = await Hive.openBox<int>('${name}_seen');
    final signatures = await Hive.openBox<SignatureHiveModel>('${name}_signatures');
    final storage = await Hive.openBox<StorageHiveModel>('${name}_storage');
    final container = ProviderContainer(
      overrides: [
        hiveContentBoxProvider.overrideWithValue(contents),
        hiveReactionBoxProvider.overrideWithValue(reactions),
        hiveSeenContentBoxProvider.overrideWithValue(seen),
        hiveSignatureBoxProvider.overrideWithValue(signatures),
        hiveStorageBoxProvider.overrideWithValue(storage),
      ],
    );
    return _Device(name, container);
  }

  /// Publie [count] contenus, et retourne leurs identifiants.
  ///
  /// - [count] : nombre de contenus à publier.
  Future<List<String>> publish(int count) async {
    final ids = <String>[];
    for (var index = 0; index < count; index++) {
      final id = '$name-${_publishedCount++}';
      final result = await container.read(saveContentUsecaseProvider)(SaveContentParams(content: _text(id)));
      expect(result.isSuccess, isTrue);
      ids.add(id);
    }
    return ids;
  }

  /// Réagit au contenu [contentId], et retourne l'identifiant de la réaction.
  ///
  /// - [contentId] : contenu auquel réagir.
  /// - [bubbleText] : texte de la réaction.
  Future<String> react(String contentId, String bubbleText) async {
    final id = '$name-reaction-$contentId';
    final now = DateTime.now();
    final reaction = Reaction(
      id: id,
      createdAt: now,
      updatedAt: now,
      contentId: contentId,
      authorId: name,
      avatarText: '(◕‿◕)',
      bubbleText: bubbleText,
    );
    final result = await container.read(saveReactionUsecaseProvider)(SaveReactionParams(reaction: reaction));
    expect(result.isSuccess, isTrue);
    return id;
  }

  /// Retourne tous les contenus de l'appareil.
  Future<List<Content>> contents() {
    return container.read(contentRepositoryProvider).getAll();
  }

  /// Retourne les identifiants des contenus de l'appareil.
  Future<Set<String>> contentIds() async {
    return (await contents()).map((content) => content.id).toSet();
  }

  /// Retourne les identifiants des réactions au contenu [contentId].
  ///
  /// - [contentId] : contenu dont on veut les réactions.
  Future<Set<String>> reactionIds(String contentId) async {
    final reactions = await container.read(reactionRepositoryProvider).getAllByContentId(contentId);
    return reactions.map((reaction) => reaction.id).toSet();
  }

  /// Vérifie que le compteur de stockage égale la somme des poids des contenus.
  ///
  /// Un contenu compté deux fois, ou enregistré sans être compté, ferait diverger ce compteur.
  Future<void> expectStorageConsistent() async {
    final storage = await container.read(getStorageUsecaseProvider)(const NoParams());
    final total = (await contents()).fold<int>(0, (sum, content) => sum + content.sizeInBytes);
    expect(storage.right?.currentSizeInBytes, total, reason: 'stockage de $name');
  }

  /// Retourne une session de cet appareil sur [transport].
  ///
  /// - [transport] : connexion avec le pair.
  ExchangeSession session(ExchangeTransportGateway transport) {
    return ExchangeSession(
      transport,
      const BinaryExchangeFrameCodecGateway(),
      container.read(buildExchangeOfferUsecaseProvider),
      container.read(selectFromExchangeOfferUsecaseProvider),
      container.read(buildExchangeBundleUsecaseProvider),
      container.read(importExchangeBundleUsecaseProvider),
      inactivityTimeout: const Duration(seconds: 5),
      sessionTimeout: const Duration(seconds: 20),
    );
  }
}

/// Retourne un contenu texte publié sur l'appareil.
///
/// - [id] : identifiant du contenu.
TextContent _text(String id) {
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
    sizeInBytes: 0,
    flair: 'france',
    title: 'Titre $id',
    body: 'Corps de $id',
  );
}

/// Fait se rencontrer deux appareils, et retourne les résultats des deux sessions.
///
/// - [first] : premier appareil.
/// - [second] : second appareil.
/// - [cutAfterSends] : nombre d'envois de [first] avant la coupure, `null` pour une connexion fiable.
Future<List<ExchangeSessionResult>> _meet(_Device first, _Device second, {int? cutAfterSends}) {
  final (firstTransport, secondTransport) = InMemoryExchangeTransportGateway.pair();
  final ExchangeTransportGateway transport = cutAfterSends == null
      ? firstTransport
      : _CuttingTransport(firstTransport, cutAfterSends);
  return Future.wait([first.session(transport).run(), second.session(secondTransport).run()]);
}

/// Déroule une vague de rencontres : les appareils forment des paires au hasard, qui échangent toutes en parallèle.
///
/// Comme sur un vrai téléphone, un appareil ne participe qu'à un échange à la fois.
///
/// - [devices] : appareils du réseau.
/// - [random] : générateur des paires.
/// - [cutChance] : probabilité qu'une connexion se coupe en cours de route.
Future<List<ExchangeSessionResult>> _wave(List<_Device> devices, Random random, {double cutChance = 0}) async {
  final shuffled = [...devices]..shuffle(random);
  final meetings = <Future<List<ExchangeSessionResult>>>[];
  for (var index = 0; index + 1 < shuffled.length; index += 2) {
    final isCut = random.nextDouble() < cutChance;
    meetings.add(_meet(shuffled[index], shuffled[index + 1], cutAfterSends: isCut ? random.nextInt(6) : null));
  }
  return (await Future.wait(meetings)).expand((results) => results).toList();
}

/// Déroule des vagues jusqu'à ce que tous les appareils possèdent [expectedIds], et retourne le nombre de vagues.
///
/// - [devices] : appareils du réseau.
/// - [expectedIds] : contenus attendus partout.
/// - [random] : générateur des paires.
/// - [maxWaves] : nombre de vagues au-delà duquel le test échoue.
/// - [cutChance] : probabilité qu'une connexion se coupe en cours de route.
Future<int> _waveUntilConverged(
  List<_Device> devices,
  Set<String> expectedIds,
  Random random, {
  required int maxWaves,
  double cutChance = 0,
}) async {
  for (var wave = 1; wave <= maxWaves; wave++) {
    await _wave(devices, random, cutChance: cutChance);
    final holdings = await Future.wait(devices.map((device) => device.contentIds()));
    if (holdings.every((held) => held.containsAll(expectedIds))) {
      return wave;
    }
  }
  final holdings = await Future.wait(devices.map((device) => device.contentIds()));
  final missing = holdings.map((held) => expectedIds.difference(held).length).toList();
  fail('pas de convergence en $maxWaves vagues, contenus manquants par appareil : $missing');
}

void main() {
  late Directory tempDir;
  late List<_Device> devices;

  setUp(() async {
    tempDir = await openTestHive();
    devices = [for (var index = 0; index < _deviceCount; index++) await _Device.open('device$index')];
  });

  tearDown(() async {
    for (final device in devices) {
      device.container.dispose();
    }
    await closeTestHive(tempDir);
  });

  for (final seed in [1, 2, 3]) {
    test('10 appareils finissent tous par tout posséder, sans doublon (tirage $seed)', () async {
      final random = Random(seed);
      final expectedIds = <String>{};
      for (final device in devices) {
        expectedIds.addAll(await device.publish(3));
      }

      await _waveUntilConverged(devices, expectedIds, random, maxWaves: 40);

      for (final device in devices) {
        final contents = await device.contents();
        expect(contents, hasLength(expectedIds.length), reason: 'doublon ou contenu inconnu sur ${device.name}');
        await device.expectStorageConsistent();
        for (final content in contents) {
          final isAuthor = content.id.startsWith('${device.name}-');
          expect(content.origin, isAuthor ? ContentOrigin.owned : ContentOrigin.public);
          expect(content.bounce == 0, isAuthor, reason: 'rebonds de ${content.id} sur ${device.name}');
        }
      }
    });
  }

  test('une fois le réseau à jour, les rencontres ne transfèrent plus rien et ne font rien échouer', () async {
    final random = Random(4);
    final expectedIds = <String>{};
    for (final device in devices) {
      expectedIds.addAll(await device.publish(2));
    }
    await _waveUntilConverged(devices, expectedIds, random, maxWaves: 40);

    for (var wave = 0; wave < 10; wave++) {
      final results = await _wave(devices, random);

      expect(results.map((result) => result.failure).toSet(), {null});
      expect(results.fold<int>(0, (sum, result) => sum + (result.report?.importedContents ?? 0)), 0);
    }
    for (final device in devices) {
      await device.expectStorageConsistent();
    }
  });

  test('des échanges continus avec de nouveaux contenus à chaque vague finissent par tout diffuser', () async {
    final random = Random(5);
    final expectedIds = <String>{};

    for (var wave = 0; wave < 20; wave++) {
      expectedIds.addAll(await devices[wave % devices.length].publish(1));
      final results = await _wave(devices, random);
      expect(results.map((result) => result.failure).toSet(), {null});
    }
    await _waveUntilConverged(devices, expectedIds, random, maxWaves: 40);

    for (final device in devices) {
      expect(await device.contents(), hasLength(expectedIds.length));
      await device.expectStorageConsistent();
    }
  });

  test('plus de contenus que le budget d\'un échange finissent quand même par circuler', () async {
    final random = Random(6);
    final expectedIds = await devices.first.publish(35);

    await _waveUntilConverged(devices, expectedIds.toSet(), random, maxWaves: 60);

    for (final device in devices) {
      await device.expectStorageConsistent();
    }
  });

  test('plus de contenus qu\'une offre ne peut en lister finissent quand même par circuler', () async {
    final random = Random(7);
    final expectedIds = <String>{};
    for (final device in devices) {
      expectedIds.addAll(await device.publish(8));
    }

    await _waveUntilConverged(devices, expectedIds, random, maxWaves: 120);
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('les connexions coupées ne laissent ni doublon ni compteur faux, et le réseau converge quand même', () async {
    final random = Random(8);
    final expectedIds = <String>{};
    for (final device in devices) {
      expectedIds.addAll(await device.publish(3));
    }

    await _waveUntilConverged(devices, expectedIds, random, maxWaves: 80, cutChance: 0.5);

    for (final device in devices) {
      expect(await device.contents(), hasLength(expectedIds.length));
      await device.expectStorageConsistent();
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('un contenu supprimé par son auteur ne lui revient jamais, même si les autres le gardent', () async {
    final random = Random(9);
    final author = devices.first;
    final ids = await author.publish(1);
    await _waveUntilConverged(devices, ids.toSet(), random, maxWaves: 30);

    final result = await author.container.read(deleteOwnContentUsecaseProvider)(
      DeleteOwnContentParams(contentId: ids.single),
    );
    expect(result.isSuccess, isTrue);

    for (var wave = 0; wave < 15; wave++) {
      await _wave(devices, random);
      expect(await author.contentIds(), isEmpty, reason: 'le contenu est revenu à la vague $wave');
    }
    await author.expectStorageConsistent();
  });

  test('les réactions de tous les appareils se propagent, y compris sur un contenu déjà possédé', () async {
    final random = Random(10);
    final ids = await devices.first.publish(1);
    await _waveUntilConverged(devices, ids.toSet(), random, maxWaves: 30);

    final expectedReactions = <String>{};
    for (final device in devices) {
      expectedReactions.add(await device.react(ids.single, 'Vu par ${device.name}'));
    }

    for (var wave = 0; wave < 40; wave++) {
      await _wave(devices, random);
      final holdings = await Future.wait(devices.map((device) => device.reactionIds(ids.single)));
      if (holdings.every((held) => held.containsAll(expectedReactions))) {
        return;
      }
    }
    final holdings = await Future.wait(devices.map((device) => device.reactionIds(ids.single)));
    fail(
      'réactions manquantes par appareil : ${holdings.map((held) => expectedReactions.length - held.length).toList()}',
    );
  });
}
