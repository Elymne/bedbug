import 'dart:io';
import 'dart:math';

import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/reaction.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/object_values/exchange_bundle.dart';
import 'package:bedbug/features/content/domain/object_values/exchange_offer.dart';
import 'package:bedbug/features/content/domain/object_values/exchange_request.dart';
import 'package:bedbug/features/content/domain/usecases/build_exchange_bundle_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/build_exchange_offer_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/delete_own_content_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/import_exchange_bundle_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/select_from_exchange_offer_usecase.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_reaction_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_seen_content_repository.dart';
import 'package:bedbug/features/content/infrastructure/gateways/json_zlib_exchange_codec_gateway.dart';
import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:bedbug/features/signature/domain/repositories/signature_repository.dart';
import 'package:bedbug/features/signature/infrastructure/datasources/hive_signature_repository.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/hive_test_helper.dart';

/// Codec utilisé pour fabriquer les messages d'un pair simulé et relire ceux de l'appareil.
const JsonZlibExchangeCodecGateway _codec = JsonZlibExchangeCodecGateway();

/// Date de référence, dans le passé, à la milliseconde près (précision du format d'échange).
final DateTime _date = DateTime.fromMillisecondsSinceEpoch(1760000000000);

/// Retourne un contenu texte de test.
///
/// - [id] : identifiant du contenu.
/// - [signatureId] : identifiant de la signature de l'auteur.
/// - [origin] : provenance du contenu.
/// - [broadcastScore] : priorité de diffusion.
/// - [bounce] : nombre de rebonds.
/// - [createdAt] : date de création, [_date] par défaut.
TextContent _text(
  String id, {
  String signatureId = localSignatureId,
  ContentOrigin origin = ContentOrigin.owned,
  double broadcastScore = 1,
  int bounce = 0,
  DateTime? createdAt,
}) {
  return TextContent(
    id: id,
    createdAt: createdAt ?? _date,
    updatedAt: createdAt ?? _date,
    signatureId: signatureId,
    origin: origin,
    broadcastScore: broadcastScore,
    survivalScore: 1,
    displayScore: 1,
    bounce: bounce,
    sizeInBytes: 100,
    flair: 'france',
    title: 'Titre $id',
    body: 'Corps',
  );
}

/// Retourne une réaction de test.
///
/// - [id] : identifiant de la réaction.
/// - [contentId] : contenu réagi.
/// - [authorId] : auteur de la réaction.
/// - [updatedAt] : date de mise à jour.
/// - [bubbleText] : bulle de texte.
Reaction _reaction(
  String id, {
  required String contentId,
  String authorId = localSignatureId,
  DateTime? updatedAt,
  String bubbleText = 'trop bien',
}) {
  return Reaction(
    id: id,
    createdAt: _date,
    updatedAt: updatedAt ?? _date,
    contentId: contentId,
    authorId: authorId,
    avatarText: '(◕‿◕)',
    bubbleText: bubbleText,
  );
}

/// Retourne une signature de pair de test.
///
/// - [pseudo] : pseudo de la signature.
Signature _signature({String pseudo = 'bedbug'}) {
  return Signature(id: '', createdAt: _date, updatedAt: _date, pseudo: pseudo, avatarText: '(◕‿◕)');
}

void main() {
  late Directory tempDir;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await openTestHive();
    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    await closeTestHive(tempDir);
  });

  /// Retourne un [SelectFromExchangeOfferUsecase] au hasard reproductible.
  ///
  /// - [seed] : graine du générateur aléatoire.
  SelectFromExchangeOfferUsecase selectUsecase({int seed = 1}) {
    return SelectFromExchangeOfferUsecase(
      container.read(contentRepositoryProvider),
      container.read(reactionRepositoryProvider),
      container.read(seenContentRepositoryProvider),
      _codec,
      Random(seed),
    );
  }

  /// Importe [contents] et [reactions] comme si un pair les envoyait en réponse à [request].
  ///
  /// - [request] : demande envoyée au pair.
  /// - [contents] : contenus envoyés par le pair.
  /// - [reactions] : réactions envoyées par le pair.
  Future<void> importFromPeer(
    ExchangeRequest request, {
    List<ExchangedContent> contents = const [],
    List<Reaction> reactions = const [],
  }) async {
    final result = await container.read(importExchangeBundleUsecaseProvider)(
      ImportExchangeBundleParams(
        requestBytes: _codec.encodeRequest(request),
        bundleBytes: _codec.encodeBundle(ExchangeBundle(contents: contents, reactions: reactions)),
      ),
    );
    expect(result.isSuccess, isTrue);
  }

  group('offre', () {
    test('propose les contenus par priorité de diffusion décroissante, avec le résumé de leurs réactions', () async {
      await container.read(contentRepositoryProvider).addMany([
        _text('low', broadcastScore: 0.2),
        _text('high', broadcastScore: 0.9),
        _text('mid', broadcastScore: 0.5),
      ]);
      final latest = _date.add(const Duration(hours: 2));
      await container.read(reactionRepositoryProvider).addMany([
        _reaction('r1', contentId: 'mid'),
        _reaction('r2', contentId: 'mid', authorId: 'other', updatedAt: latest),
      ]);

      final result = await container.read(buildExchangeOfferUsecaseProvider)(const NoParams());
      final offer = _codec.decodeOffer(result.right!);

      expect(offer.contents.map((content) => content.id), ['high', 'mid', 'low']);
      expect(offer.contents[1].reactionCount, 2);
      expect(offer.contents[1].latestReactionAt, latest);
      expect(offer.contents[0].latestReactionAt, isNull);
    });
  });

  group('sélection', () {
    test('écarte les contenus déjà possédés ou déjà vus, et respecte le budget', () async {
      await container.read(contentRepositoryProvider).addOne(_text('owned'));
      await container.read(seenContentRepositoryProvider).addMany(['seen'], DateTime.now());
      const offer = ExchangeOffer(
        contents: [
          OfferedContent(id: 'owned', sizeInBytes: 10, reactionCount: 0),
          OfferedContent(id: 'seen', sizeInBytes: 10, reactionCount: 0),
          OfferedContent(id: 'big', sizeInBytes: 5000, reactionCount: 0),
          OfferedContent(id: 'small', sizeInBytes: 10, reactionCount: 0),
        ],
      );

      final result = await selectUsecase()(
        SelectFromExchangeOfferParams(offerBytes: _codec.encodeOffer(offer), maxBytes: 1000),
      );
      final request = _codec.decodeRequest(result.right!);

      expect(request.contentIds, ['small']);
      expect(request.reactionContentIds, isEmpty);
    });

    test('favorise le haut de l\'offre sans jamais exclure le bas', () async {
      final offer = ExchangeOffer(
        contents: [
          for (var index = 0; index < 10; index++) OfferedContent(id: 'c$index', sizeInBytes: 10, reactionCount: 0),
        ],
      );
      final offerBytes = _codec.encodeOffer(offer);
      final usecase = selectUsecase(seed: 42);
      final counts = <String, int>{};
      for (var draw = 0; draw < 2000; draw++) {
        final result = await usecase(SelectFromExchangeOfferParams(offerBytes: offerBytes, maxContents: 1));
        final picked = _codec.decodeRequest(result.right!).contentIds.single;
        counts.update(picked, (count) => count + 1, ifAbsent: () => 1);
      }

      final first = counts['c0'] ?? 0;
      final last = counts['c9'] ?? 0;
      // Poids 1 contre 0,2 : le premier sort environ cinq fois plus souvent que le dernier.
      expect(first, greaterThan(last * 3));
      expect(last, greaterThan(0));
    });

    test('redemande les réactions d\'un contenu possédé si le pair en a de plus récentes', () async {
      await container.read(contentRepositoryProvider).addMany([_text('fresh'), _text('stale')]);
      await container.read(reactionRepositoryProvider).addMany([
        _reaction('r1', contentId: 'fresh', updatedAt: _date.add(const Duration(days: 1))),
        _reaction('r2', contentId: 'stale'),
      ]);
      final offer = ExchangeOffer(
        contents: [
          OfferedContent(id: 'fresh', sizeInBytes: 10, reactionCount: 1, latestReactionAt: _date),
          OfferedContent(
            id: 'stale',
            sizeInBytes: 10,
            reactionCount: 1,
            latestReactionAt: _date.add(const Duration(days: 1)),
          ),
        ],
      );

      final result = await selectUsecase()(SelectFromExchangeOfferParams(offerBytes: _codec.encodeOffer(offer)));
      final request = _codec.decodeRequest(result.right!);

      expect(request.contentIds, isEmpty);
      expect(request.reactionContentIds, ['stale']);
    });
  });

  group('lot', () {
    test('joint la signature locale aux contenus de l\'utilisateur, aucune aux anonymes, et leurs réactions', () async {
      await container
          .read(signatureRepositoryProvider)
          .saveLocal(
            Signature(id: localSignatureId, createdAt: _date, updatedAt: _date, pseudo: 'moi', avatarText: '(・ω・)'),
          );
      await container.read(contentRepositoryProvider).addMany([
        _text('mine'),
        _text('anonymous', signatureId: anonymousSignatureId),
        _text('not-requested'),
      ]);
      await container.read(reactionRepositoryProvider).addMany([
        _reaction('r1', contentId: 'mine'),
        _reaction('r2', contentId: 'not-requested'),
      ]);
      const request = ExchangeRequest(contentIds: ['mine', 'anonymous', 'unknown'], reactionContentIds: []);

      final result = await container.read(buildExchangeBundleUsecaseProvider)(
        BuildExchangeBundleParams(requestBytes: _codec.encodeRequest(request)),
      );
      final bundle = _codec.decodeBundle(result.right!);

      expect(bundle.contents.map((exchanged) => exchanged.content.id), ['mine', 'anonymous']);
      expect(bundle.contents[0].signature?.pseudo, 'moi');
      expect(bundle.contents[0].signature?.id, isEmpty);
      expect(bundle.contents[1].signature, isNull);
      expect(bundle.reactions.map((reaction) => reaction.id), ['r1']);
    });
  });

  group('import', () {
    test('enregistre un contenu demandé en fixant ses champs propres à l\'appareil, et ignore le reste', () async {
      final future = DateTime.now().add(const Duration(days: 365));

      await importFromPeer(
        const ExchangeRequest(contentIds: ['wanted'], reactionContentIds: []),
        contents: [
          ExchangedContent(
            content: _text('wanted', bounce: 3, createdAt: future),
            signature: _signature(),
          ),
          ExchangedContent(content: _text('pushed'), signature: _signature()),
        ],
      );

      final repository = container.read(contentRepositoryProvider);
      expect(await repository.getById('pushed'), isNull);
      final saved = (await repository.getById('wanted'))!;
      expect(saved.origin, ContentOrigin.public);
      expect(saved.bounce, 4);
      expect(saved.createdAt.isAfter(DateTime.now()), isFalse);
      expect(saved.signatureId, startsWith(peerSignatureIdPrefix));
      final signature = await container.read(signatureRepositoryProvider).getById(saved.signatureId);
      expect(signature?.pseudo, 'bedbug');
    });

    test('regroupe les contenus d\'une même signature, et passe en anonyme une signature invalide', () async {
      await importFromPeer(
        const ExchangeRequest(contentIds: ['a', 'b', 'c', 'd'], reactionContentIds: []),
        contents: [
          ExchangedContent(content: _text('a'), signature: _signature()),
          ExchangedContent(content: _text('b'), signature: _signature()),
          ExchangedContent(
            content: _text('c'),
            signature: _signature(pseudo: 'autre'),
          ),
          ExchangedContent(
            content: _text('d'),
            signature: _signature(pseudo: '!!'),
          ),
        ],
      );

      final repository = container.read(contentRepositoryProvider);
      final contents = {for (final content in await repository.getAll()) content.id: content};
      expect(contents['a']!.signatureId, contents['b']!.signatureId);
      expect(contents['c']!.signatureId, isNot(contents['a']!.signatureId));
      expect(contents['d']!.signatureId, anonymousSignatureId);
    });

    test('ne réimporte pas un contenu que l\'utilisateur a supprimé', () async {
      await container.read(contentRepositoryProvider).addOne(_text('regretted'));
      await container.read(deleteOwnContentUsecaseProvider)(const DeleteOwnContentParams(contentId: 'regretted'));

      await importFromPeer(
        const ExchangeRequest(contentIds: ['regretted'], reactionContentIds: []),
        contents: [ExchangedContent(content: _text('regretted'))],
      );

      expect(await container.read(contentRepositoryProvider).getById('regretted'), isNull);
    });

    test('importe les réactions sans auteur, sans jamais remplacer celle de l\'utilisateur', () async {
      await container.read(contentRepositoryProvider).addOne(_text('post', signatureId: 'someone'));
      await container.read(reactionRepositoryProvider).addOne(_reaction('mine', contentId: 'post'));

      await importFromPeer(
        const ExchangeRequest(contentIds: [], reactionContentIds: ['post']),
        reactions: [
          _reaction('mine', contentId: 'post', authorId: '', updatedAt: DateTime.now(), bubbleText: 'piratée'),
          _reaction('theirs', contentId: 'post', authorId: ''),
        ],
      );
      await importFromPeer(
        const ExchangeRequest(contentIds: [], reactionContentIds: ['post']),
        reactions: [
          _reaction(
            'theirs',
            contentId: 'post',
            authorId: '',
            updatedAt: _date.add(const Duration(days: 1)),
            bubbleText: 'modifiée',
          ),
        ],
      );

      final reactions = {
        for (final reaction in await container.read(reactionRepositoryProvider).getAllByContentId('post'))
          reaction.id: reaction,
      };
      expect(reactions.keys, unorderedEquals(['mine', 'theirs']));
      expect(reactions['mine']!.authorId, localSignatureId);
      expect(reactions['mine']!.bubbleText, 'trop bien');
      expect(reactions['theirs']!.authorId, 'theirs');
      expect(reactions['theirs']!.bubbleText, 'modifiée');
    });

    test('un cycle complet entre deux appareils transfère les contenus choisis', () async {
      // Côté A : l'appareil courant, avec trois contenus.
      await container.read(contentRepositoryProvider).addMany([_text('a1'), _text('a2'), _text('a3')]);
      final offerBytes = (await container.read(buildExchangeOfferUsecaseProvider)(const NoParams())).right!;

      // Côté B, simulé : il ne possède rien et demande tout.
      final offer = _codec.decodeOffer(offerBytes);
      final request = ExchangeRequest(
        contentIds: offer.contents.map((content) => content.id).toList(),
        reactionContentIds: const [],
      );
      final bundleBytes = (await container.read(buildExchangeBundleUsecaseProvider)(
        BuildExchangeBundleParams(requestBytes: _codec.encodeRequest(request)),
      )).right!;

      // B importe chez lui : on vide la base pour jouer son rôle.
      await container.read(contentRepositoryProvider).deleteAll();
      final result = await container.read(importExchangeBundleUsecaseProvider)(
        ImportExchangeBundleParams(requestBytes: _codec.encodeRequest(request), bundleBytes: bundleBytes),
      );

      expect(result.right?.importedContents, 3);
      final contents = await container.read(contentRepositoryProvider).getAll();
      expect(contents.map((Content content) => content.origin).toSet(), {ContentOrigin.public});
    });
  });
}
