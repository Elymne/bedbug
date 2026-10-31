import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/media_content.dart';
import 'package:bedbug/features/content/domain/entities/reaction.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/extensions/flair_extension.dart';
import 'package:bedbug/features/content/domain/object_values/content_media.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_reaction_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_seen_content_repository.dart';
import 'package:bedbug/features/exchange/domain/object_values/exchange_bundle.dart';
import 'package:bedbug/features/exchange/domain/object_values/exchange_import_report.dart';
import 'package:bedbug/features/exchange/domain/object_values/exchange_offer.dart';
import 'package:bedbug/features/exchange/domain/object_values/exchange_request.dart';
import 'package:bedbug/features/exchange/domain/usecases/build_exchange_bundle_usecase.dart';
import 'package:bedbug/features/exchange/domain/usecases/build_exchange_offer_usecase.dart';
import 'package:bedbug/features/exchange/domain/usecases/import_exchange_bundle_usecase.dart';
import 'package:bedbug/features/exchange/domain/usecases/select_from_exchange_offer_usecase.dart';
import 'package:bedbug/features/exchange/infrastructure/gateways/json_zlib_exchange_codec_gateway.dart';
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

/// Message qui n'est pas un message du format d'échange.
final Uint8List _garbage = Uint8List.fromList([1, 2, 3, 4]);

/// Retourne un contenu texte de test.
///
/// - [id] : identifiant du contenu.
/// - [signatureId] : identifiant de la signature de l'auteur.
/// - [broadcastScore] : priorité de diffusion.
/// - [bounce] : nombre de rebonds.
/// - [createdAt] : date de création, [_date] par défaut.
/// - [updatedAt] : date de mise à jour, [createdAt] par défaut.
/// - [flair] : flair du contenu.
/// - [body] : corps du contenu.
TextContent _text(
  String id, {
  String signatureId = localSignatureId,
  double broadcastScore = 1,
  int bounce = 0,
  DateTime? createdAt,
  DateTime? updatedAt,
  String flair = 'france',
  String body = 'Corps',
}) {
  return TextContent(
    id: id,
    createdAt: createdAt ?? _date,
    updatedAt: updatedAt ?? createdAt ?? _date,
    signatureId: signatureId,
    origin: ContentOrigin.owned,
    broadcastScore: broadcastScore,
    survivalScore: 1,
    displayScore: 1,
    bounce: bounce,
    sizeInBytes: 100,
    flair: flair,
    title: 'Titre $id',
    body: body,
  );
}

/// Retourne un contenu média de test.
///
/// - [id] : identifiant du contenu.
/// - [mediaCount] : nombre de médias.
MediaContent _media(String id, int mediaCount) {
  return MediaContent(
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
    media: [
      for (var index = 0; index < mediaCount; index++)
        ContentMedia(url: 'https://example.com/$index.png', kind: MediaKind.image),
    ],
    title: 'Titre $id',
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
  String authorId = '',
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

/// Retourne une signature telle qu'elle arrive d'un pair.
///
/// - [id] : identifiant annoncé par le pair, qui ne doit jamais être cru.
/// - [pseudo] : pseudo.
/// - [avatarText] : icône.
/// - [colorArgb] : couleur du ghost.
/// - [ghostSpeed] : vitesse du ghost.
/// - [bio] : description.
Signature _signature({
  String id = '',
  String pseudo = 'bedbug',
  String avatarText = '(◕‿◕)',
  int? colorArgb,
  double ghostSpeed = 1,
  String? bio,
}) {
  return Signature(
    id: id,
    createdAt: _date,
    updatedAt: _date,
    pseudo: pseudo,
    avatarText: avatarText,
    colorArgb: colorArgb,
    ghostSpeed: ghostSpeed,
    bio: bio,
  );
}

/// Retourne une offre de [count] contenus légers.
///
/// - [count] : nombre de contenus.
/// - [sizeInBytes] : poids annoncé de chaque contenu.
ExchangeOffer _offerOf(int count, {int sizeInBytes = 10}) {
  return ExchangeOffer(
    contents: [
      for (var index = 0; index < count; index++)
        OfferedContent(id: 'c$index', sizeInBytes: sizeInBytes, reactionCount: 0),
    ],
  );
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

  /// Retourne l'offre construite par l'appareil.
  Future<ExchangeOffer> buildOffer() async {
    final result = await container.read(buildExchangeOfferUsecaseProvider)(const NoParams());
    return _codec.decodeOffer(result.right!);
  }

  /// Retourne la demande de l'appareil pour [offer].
  ///
  /// - [offer] : offre du pair.
  /// - [maxContents] : nombre maximal de contenus à demander.
  /// - [maxBytes] : poids cumulé maximal.
  Future<ExchangeRequest> select(
    ExchangeOffer offer, {
    int maxContents = defaultMaxRequestedContents,
    int maxBytes = defaultMaxRequestedBytes,
  }) async {
    final usecase = SelectFromExchangeOfferUsecase(
      container.read(contentRepositoryProvider),
      container.read(reactionRepositoryProvider),
      container.read(seenContentRepositoryProvider),
      _codec,
      Random(1),
    );
    final result = await usecase(
      SelectFromExchangeOfferParams(
        offerBytes: _codec.encodeOffer(offer),
        maxContents: maxContents,
        maxBytes: maxBytes,
      ),
    );
    return _codec.decodeRequest(result.right!);
  }

  /// Retourne le lot construit par l'appareil pour [request].
  ///
  /// - [request] : demande du pair.
  Future<ExchangeBundle> buildBundle(ExchangeRequest request) async {
    final result = await container.read(buildExchangeBundleUsecaseProvider)(
      BuildExchangeBundleParams(requestBytes: _codec.encodeRequest(request)),
    );
    return _codec.decodeBundle(result.right!);
  }

  /// Importe [contents] et [reactions] comme réponse d'un pair à une demande portant sur [contentIds] et
  /// [reactionContentIds], et retourne le bilan.
  ///
  /// - [contentIds] : contenus demandés.
  /// - [reactionContentIds] : contenus dont les réactions sont demandées.
  /// - [contents] : contenus envoyés par le pair.
  /// - [reactions] : réactions envoyées par le pair.
  Future<ExchangeImportReport> importFromPeer({
    List<String> contentIds = const [],
    List<String> reactionContentIds = const [],
    List<ExchangedContent> contents = const [],
    List<Reaction> reactions = const [],
  }) async {
    final result = await container.read(importExchangeBundleUsecaseProvider)(
      ImportExchangeBundleParams(
        requestBytes: _codec.encodeRequest(
          ExchangeRequest(contentIds: contentIds, reactionContentIds: reactionContentIds),
        ),
        bundleBytes: _codec.encodeBundle(ExchangeBundle(contents: contents, reactions: reactions)),
      ),
    );
    return result.right!;
  }

  /// Retourne le contenu enregistré sous [id].
  ///
  /// - [id] : identifiant du contenu.
  Future<Content?> stored(String id) {
    return container.read(contentRepositoryProvider).getById(id);
  }

  /// Retourne la signature enregistrée pour le contenu [id].
  ///
  /// - [id] : identifiant du contenu.
  Future<Signature?> storedSignatureOf(String id) async {
    final content = await stored(id);
    return container.read(signatureRepositoryProvider).getById(content!.signatureId);
  }

  group('BuildExchangeOfferUsecase', () {
    test('une base vide donne une offre vide', () async {
      expect((await buildOffer()).contents, isEmpty);
    });

    test('une offre variée propose peu à peu les contenus hors des plus prioritaires', () async {
      await container.read(contentRepositoryProvider).addMany([
        for (var index = 0; index < 120; index++) _text('c$index', broadcastScore: 1),
      ]);

      final offeredIds = <String>{};
      for (var round = 0; round < 10; round++) {
        final offer = await buildOffer();
        expect(offer.contents, hasLength(maxOfferedContents));
        offeredIds.addAll(offer.contents.map((content) => content.id));
      }

      expect(offeredIds.length, greaterThan(maxOfferedContents));
    });

    test('commence par les contenus les plus prioritaires, dans la limite de maxOfferedContents', () async {
      await container.read(contentRepositoryProvider).addMany([
        for (var index = 0; index < maxOfferedContents + 10; index++) _text('c$index', broadcastScore: index / 100),
      ]);

      final offer = await buildOffer();

      expect(offer.contents, hasLength(maxOfferedContents));
      expect(offer.contents.first.id, 'c${maxOfferedContents + 9}');
      expect(offer.contents.take(priorityOfferedContents).map((content) => content.id), [
        for (var index = 0; index < priorityOfferedContents; index++) 'c${maxOfferedContents + 9 - index}',
      ]);
    });

    test('annonce le poids stocké de chaque contenu', () async {
      await container.read(contentRepositoryProvider).addOne(_text('post'));

      expect((await buildOffer()).contents.single.sizeInBytes, 100);
    });

    test('ne révèle que l\'identifiant, le poids et le résumé des réactions', () async {
      await container.read(contentRepositoryProvider).addOne(_text('post', signatureId: 'peer-secret'));

      final result = await container.read(buildExchangeOfferUsecaseProvider)(const NoParams());
      final decoded = String.fromCharCodes(zlib.decode(result.right!));

      expect(decoded, isNot(contains('peer-secret')));
      expect(decoded, isNot(contains('Titre')));
    });
  });

  group('SelectFromExchangeOfferUsecase', () {
    test('une offre vide donne une demande vide', () async {
      final request = await select(const ExchangeOffer(contents: []));

      expect(request.contentIds, isEmpty);
      expect(request.reactionContentIds, isEmpty);
    });

    test('ne demande jamais plus de contenus que maxContents', () async {
      expect((await select(_offerOf(40), maxContents: 7)).contentIds, hasLength(7));
    });

    test('la limite par défaut borne une offre pleine', () async {
      expect((await select(_offerOf(maxOfferedContents))).contentIds, hasLength(defaultMaxRequestedContents));
    });

    test('tient le poids cumulé dans le budget', () async {
      final request = await select(_offerOf(20, sizeInBytes: 100), maxBytes: 350);

      expect(request.contentIds, hasLength(3));
    });

    test('accepte un contenu dont le poids égale exactement le budget', () async {
      expect((await select(_offerOf(1, sizeInBytes: 500), maxBytes: 500)).contentIds, ['c0']);
    });

    test('saute un contenu trop lourd au profit des petits suivants', () async {
      const offer = ExchangeOffer(
        contents: [
          OfferedContent(id: 'huge', sizeInBytes: 10000, reactionCount: 0),
          OfferedContent(id: 'tiny', sizeInBytes: 10, reactionCount: 0),
        ],
      );

      expect((await select(offer, maxBytes: 100)).contentIds, ['tiny']);
    });

    test('ignore ce qui dépasse maxOfferedContents', () async {
      final offer = _offerOf(maxOfferedContents + 20);

      final request = await select(offer, maxContents: 1000, maxBytes: 1 << 30);

      expect(request.contentIds, hasLength(maxOfferedContents));
      expect(request.contentIds, isNot(contains('c${maxOfferedContents + 5}')));
    });

    test('ignore les doublons et les poids négatifs', () async {
      const offer = ExchangeOffer(
        contents: [
          OfferedContent(id: 'twice', sizeInBytes: 10, reactionCount: 0),
          OfferedContent(id: 'twice', sizeInBytes: 10, reactionCount: 0),
          OfferedContent(id: 'negative', sizeInBytes: -5000, reactionCount: 0),
        ],
      );

      expect((await select(offer)).contentIds, ['twice']);
    });

    test('ne demande les réactions que des contenus possédés', () async {
      final offer = ExchangeOffer(
        contents: [OfferedContent(id: 'unknown', sizeInBytes: 10, reactionCount: 3, latestReactionAt: _date)],
      );

      final request = await select(offer);

      expect(request.contentIds, ['unknown']);
      expect(request.reactionContentIds, isEmpty);
    });

    test('redemande les réactions quand le pair en a plus, même aussi récentes', () async {
      await container.read(contentRepositoryProvider).addOne(_text('post'));
      await container.read(reactionRepositoryProvider).addOne(_reaction('r1', contentId: 'post', authorId: 'a'));
      final offer = ExchangeOffer(
        contents: [OfferedContent(id: 'post', sizeInBytes: 10, reactionCount: 2, latestReactionAt: _date)],
      );

      expect((await select(offer)).reactionContentIds, ['post']);
    });

    test('ne redemande rien quand le pair n\'a pas de réaction', () async {
      await container.read(contentRepositoryProvider).addOne(_text('post'));
      const offer = ExchangeOffer(contents: [OfferedContent(id: 'post', sizeInBytes: 10, reactionCount: 0)]);

      expect((await select(offer)).reactionContentIds, isEmpty);
    });

    test('borne les réactions redemandées à maxReactionRefreshContents', () async {
      final ids = [for (var index = 0; index < maxReactionRefreshContents + 5; index++) 'c$index'];
      await container.read(contentRepositoryProvider).addMany([for (final id in ids) _text(id)]);
      final offer = ExchangeOffer(
        contents: [
          for (final id in ids) OfferedContent(id: id, sizeInBytes: 10, reactionCount: 1, latestReactionAt: _date),
        ],
      );

      expect((await select(offer)).reactionContentIds, hasLength(maxReactionRefreshContents));
    });

    test('refuse une offre illisible', () async {
      final result = await container.read(selectFromExchangeOfferUsecaseProvider)(
        SelectFromExchangeOfferParams(offerBytes: _garbage),
      );

      expect(result.left, SelectFromExchangeOfferFailure.invalidOffer);
    });
  });

  group('BuildExchangeBundleUsecase', () {
    test('une demande vide donne un lot vide', () async {
      await container.read(contentRepositoryProvider).addOne(_text('post'));

      final bundle = await buildBundle(const ExchangeRequest(contentIds: [], reactionContentIds: []));

      expect(bundle.contents, isEmpty);
      expect(bundle.reactions, isEmpty);
    });

    test('tronque une demande plus longue que ce qu\'un pair honnête envoie', () async {
      final ids = [for (var index = 0; index < defaultMaxRequestedContents + 10; index++) 'c$index'];
      await container.read(contentRepositoryProvider).addMany([for (final id in ids) _text(id)]);

      final bundle = await buildBundle(ExchangeRequest(contentIds: ids, reactionContentIds: const []));

      expect(bundle.contents, hasLength(defaultMaxRequestedContents));
    });

    test('tronque les réactions redemandées', () async {
      final ids = [for (var index = 0; index < maxReactionRefreshContents + 5; index++) 'c$index'];
      await container.read(contentRepositoryProvider).addMany([for (final id in ids) _text(id)]);
      await container.read(reactionRepositoryProvider).addMany([
        for (final id in ids) _reaction('r-$id', contentId: id, authorId: 'a'),
      ]);

      final bundle = await buildBundle(ExchangeRequest(contentIds: const [], reactionContentIds: ids));

      expect(bundle.reactions, hasLength(maxReactionRefreshContents));
    });

    test('ne répète pas un contenu demandé deux fois', () async {
      await container.read(contentRepositoryProvider).addOne(_text('post'));

      final bundle = await buildBundle(const ExchangeRequest(contentIds: ['post', 'post'], reactionContentIds: []));

      expect(bundle.contents, hasLength(1));
    });

    test('ne répète pas les réactions d\'un contenu demandé des deux façons', () async {
      await container.read(contentRepositoryProvider).addOne(_text('post'));
      await container.read(reactionRepositoryProvider).addOne(_reaction('r1', contentId: 'post', authorId: 'a'));

      final bundle = await buildBundle(const ExchangeRequest(contentIds: ['post'], reactionContentIds: ['post']));

      expect(bundle.reactions, hasLength(1));
    });

    test('ignore les contenus et les réactions inconnus', () async {
      final bundle = await buildBundle(const ExchangeRequest(contentIds: ['ghost'], reactionContentIds: ['ghost']));

      expect(bundle.contents, isEmpty);
      expect(bundle.reactions, isEmpty);
    });

    test('n\'envoie aucun identifiant de signature ni champ propre à l\'appareil', () async {
      await container.read(contentRepositoryProvider).addOne(_text('post', signatureId: 'peer-secret'));
      final repository = container.read(signatureRepositoryProvider);
      await repository.saveMany([_signature(id: 'peer-secret')]);

      final bundle = await buildBundle(const ExchangeRequest(contentIds: ['post'], reactionContentIds: []));

      final exchanged = bundle.contents.single;
      expect(exchanged.content.signatureId, isEmpty);
      expect(exchanged.content.origin, ContentOrigin.public);
      expect(exchanged.content.sizeInBytes, 0);
      expect(exchanged.signature?.id, isEmpty);
    });

    test('relaie la signature d\'un contenu reçu d\'un pair', () async {
      await container.read(signatureRepositoryProvider).saveMany([_signature(id: 'peer-1', pseudo: 'relais')]);
      await container.read(contentRepositoryProvider).addOne(_text('post', signatureId: 'peer-1'));

      final bundle = await buildBundle(const ExchangeRequest(contentIds: ['post'], reactionContentIds: []));

      expect(bundle.contents.single.signature?.pseudo, 'relais');
    });

    test('un contenu dont la signature n\'est plus connue part sans signature', () async {
      await container.read(contentRepositoryProvider).addOne(_text('post', signatureId: 'peer-oublié'));

      final bundle = await buildBundle(const ExchangeRequest(contentIds: ['post'], reactionContentIds: []));

      expect(bundle.contents.single.signature, isNull);
    });

    test('sans signature configurée, un contenu de l\'utilisateur part sans signature', () async {
      await container.read(contentRepositoryProvider).addOne(_text('post'));

      final bundle = await buildBundle(const ExchangeRequest(contentIds: ['post'], reactionContentIds: []));

      expect(bundle.contents.single.signature, isNull);
    });

    test('les réactions partent sans auteur', () async {
      await container.read(contentRepositoryProvider).addOne(_text('post'));
      await container
          .read(reactionRepositoryProvider)
          .addOne(_reaction('r1', contentId: 'post', authorId: localSignatureId));

      final bundle = await buildBundle(const ExchangeRequest(contentIds: ['post'], reactionContentIds: []));

      expect(bundle.reactions.single.authorId, isEmpty);
    });

    test('refuse une demande illisible', () async {
      final result = await container.read(buildExchangeBundleUsecaseProvider)(
        BuildExchangeBundleParams(requestBytes: _garbage),
      );

      expect(result.left, BuildExchangeBundleFailure.invalidRequest);
    });
  });

  group('ImportExchangeBundleUsecase : contenus', () {
    test('refuse un lot ou une demande illisibles', () async {
      final usecase = container.read(importExchangeBundleUsecaseProvider);
      final valid = _codec.encodeBundle(const ExchangeBundle(contents: [], reactions: []));
      final request = _codec.encodeRequest(const ExchangeRequest(contentIds: [], reactionContentIds: []));

      final badBundle = await usecase(ImportExchangeBundleParams(requestBytes: request, bundleBytes: _garbage));
      final badRequest = await usecase(ImportExchangeBundleParams(requestBytes: _garbage, bundleBytes: valid));

      expect(badBundle.left, ImportExchangeBundleFailure.invalidBundle);
      expect(badRequest.left, ImportExchangeBundleFailure.invalidBundle);
    });

    test('compte ce qui a été importé et écarté', () async {
      final report = await importFromPeer(
        contentIds: ['wanted'],
        contents: [
          ExchangedContent(content: _text('wanted')),
          ExchangedContent(content: _text('pushed')),
        ],
      );

      expect(report.importedContents, 1);
      expect(report.rejectedContents, 1);
    });

    test('n\'importe qu\'une fois un contenu présent deux fois dans le lot', () async {
      final report = await importFromPeer(
        contentIds: ['twice'],
        contents: [
          ExchangedContent(content: _text('twice')),
          ExchangedContent(content: _text('twice')),
        ],
      );

      expect(report.importedContents, 1);
      expect(report.rejectedContents, 1);
    });

    test('ne remplace jamais un contenu déjà possédé', () async {
      await container.read(contentRepositoryProvider).addOne(_text('mine', body: 'original'));

      final report = await importFromPeer(
        contentIds: ['mine'],
        contents: [ExchangedContent(content: _text('mine', body: 'falsifié'))],
      );

      expect(report.importedContents, 0);
      expect(((await stored('mine'))! as TextContent).body, 'original');
      expect((await stored('mine'))!.origin, ContentOrigin.owned);
    });

    test('ne réimporte pas un contenu déjà vu', () async {
      await container.read(seenContentRepositoryProvider).addMany(['seen'], DateTime.now());

      final report = await importFromPeer(
        contentIds: ['seen'],
        contents: [ExchangedContent(content: _text('seen'))],
      );

      expect(report.importedContents, 0);
      expect(await stored('seen'), isNull);
    });

    test('réaccepte un contenu dont la mémoire a expiré', () async {
      final expired = DateTime.now().subtract(seenContentRetention + const Duration(days: 1));
      await container.read(seenContentRepositoryProvider).addMany(['old'], expired);

      final report = await importFromPeer(
        contentIds: ['old'],
        contents: [ExchangedContent(content: _text('old'))],
      );

      expect(report.importedContents, 1);
    });

    test('mémorise comme vu un contenu reçu mais écarté, pour ne pas le redemander', () async {
      await importFromPeer(
        contentIds: ['invalid'],
        contents: [ExchangedContent(content: _text('invalid', flair: '   '))],
      );

      final seen = await container.read(seenContentRepositoryProvider).getSeenAmong({'invalid'});
      expect(seen, {'invalid'});
    });

    test('ne mémorise pas un contenu que le pair n\'a pas été invité à envoyer', () async {
      await importFromPeer(
        contentIds: [],
        contents: [ExchangedContent(content: _text('pushed'))],
      );

      expect(await container.read(seenContentRepositoryProvider).getSeenAmong({'pushed'}), isEmpty);
    });

    test('ne garde pas les scores ni la provenance du pair', () async {
      await importFromPeer(
        contentIds: ['post'],
        contents: [ExchangedContent(content: _text('post'))],
      );

      final saved = (await stored('post'))!;
      expect(saved.origin, ContentOrigin.public);
      expect(saved.isOwned, isFalse);
    });

    test('recalcule le poids réel, sans croire le pair', () async {
      await importFromPeer(
        contentIds: ['post'],
        contents: [ExchangedContent(content: _text('post', body: 'abcd'))],
      );

      expect((await stored('post'))!.sizeInBytes, 'Titre post'.length + 4);
    });

    test('borne un nombre de rebonds extravagant', () async {
      await importFromPeer(
        contentIds: ['post'],
        contents: [ExchangedContent(content: _text('post', bounce: 999999))],
      );

      expect((await stored('post'))!.bounce, maxReceivedBounce + 1);
    });

    test('ramène un nombre de rebonds négatif à zéro avant de l\'incrémenter', () async {
      await importFromPeer(
        contentIds: ['post'],
        contents: [ExchangedContent(content: _text('post', bounce: -50))],
      );

      expect((await stored('post'))!.bounce, 1);
    });

    test('ramène les dates futures à la date du jour', () async {
      final future = DateTime.now().add(const Duration(days: 30));

      await importFromPeer(
        contentIds: ['post'],
        contents: [ExchangedContent(content: _text('post', createdAt: future))],
      );

      final saved = (await stored('post'))!;
      expect(saved.createdAt.isAfter(DateTime.now()), isFalse);
      expect(saved.updatedAt.isAfter(DateTime.now()), isFalse);
    });

    test('remet à niveau une date de mise à jour antérieure à la création', () async {
      await importFromPeer(
        contentIds: ['post'],
        contents: [
          ExchangedContent(
            content: _text('post', createdAt: _date, updatedAt: _date.subtract(const Duration(days: 3))),
          ),
        ],
      );

      final saved = (await stored('post'))!;
      expect(saved.updatedAt, saved.createdAt);
    });

    test('normalise le flair', () async {
      await importFromPeer(
        contentIds: ['post'],
        contents: [ExchangedContent(content: _text('post', flair: '  F/France '))],
      );

      expect((await stored('post'))!.flair, 'france');
    });

    test('écarte un flair vide ou trop long', () async {
      final report = await importFromPeer(
        contentIds: ['empty', 'long'],
        contents: [
          ExchangedContent(content: _text('empty', flair: 'f/')),
          ExchangedContent(content: _text('long', flair: 'a' * (maxFlairLength + 1))),
        ],
      );

      expect(report.importedContents, 0);
      expect(report.rejectedContents, 2);
    });

    test('accepte un flair de longueur maximale', () async {
      final report = await importFromPeer(
        contentIds: ['post'],
        contents: [ExchangedContent(content: _text('post', flair: 'a' * maxFlairLength))],
      );

      expect(report.importedContents, 1);
    });

    test('écarte un contenu plus lourd que maxReceivedContentBytes', () async {
      final report = await importFromPeer(
        contentIds: ['heavy'],
        contents: [ExchangedContent(content: _text('heavy', body: 'a' * (maxReceivedContentBytes + 1)))],
      );

      expect(report.importedContents, 0);
      expect(await stored('heavy'), isNull);
    });

    test('écarte un média vide ou avec trop de médias', () async {
      final report = await importFromPeer(
        contentIds: ['none', 'many', 'fine'],
        contents: [
          ExchangedContent(content: _media('none', 0)),
          ExchangedContent(content: _media('many', maxMediaPerContent + 1)),
          ExchangedContent(content: _media('fine', maxMediaPerContent)),
        ],
      );

      expect(report.importedContents, 1);
      expect(await stored('fine'), isNotNull);
    });

    test('un contenu écarté n\'empêche pas d\'importer les suivants', () async {
      final report = await importFromPeer(
        contentIds: ['bad', 'good'],
        contents: [
          ExchangedContent(content: _text('bad', flair: '')),
          ExchangedContent(content: _text('good')),
        ],
      );

      expect(report.importedContents, 1);
      expect(report.rejectedContents, 1);
    });
  });

  group('ImportExchangeBundleUsecase : signatures', () {
    test('un contenu sans signature s\'affiche en anonyme', () async {
      await importFromPeer(
        contentIds: ['post'],
        contents: [ExchangedContent(content: _text('post'))],
      );

      expect((await stored('post'))!.signatureId, anonymousSignatureId);
    });

    test('n\'enregistre pas de signature pour un contenu écarté', () async {
      await importFromPeer(
        contentIds: ['bad'],
        contents: [
          ExchangedContent(
            content: _text('bad', flair: ''),
            signature: _signature(pseudo: 'fantome'),
          ),
        ],
      );

      expect(container.read(hiveSignatureBoxProvider).isEmpty, isTrue);
    });

    test('une signature reçue ne prend jamais la place de celle de l\'utilisateur', () async {
      await container
          .read(signatureRepositoryProvider)
          .saveLocal(Signature(id: localSignatureId, createdAt: _date, updatedAt: _date, pseudo: 'moi'));

      await importFromPeer(
        contentIds: ['post'],
        contents: [
          ExchangedContent(
            content: _text('post'),
            signature: _signature(id: localSignatureId),
          ),
        ],
      );

      expect((await stored('post'))!.signatureId, startsWith(peerSignatureIdPrefix));
      expect((await container.read(signatureRepositoryProvider).getLocal())?.pseudo, 'moi');
    });

    test('la moindre différence donne une autre signature', () async {
      await importFromPeer(
        contentIds: ['a', 'b', 'c'],
        contents: [
          ExchangedContent(content: _text('a'), signature: _signature()),
          ExchangedContent(content: _text('b'), signature: _signature(colorArgb: 0xFF112233)),
          ExchangedContent(
            content: _text('c'),
            signature: _signature(bio: 'bonjour'),
          ),
        ],
      );

      final ids = {
        for (final id in ['a', 'b', 'c']) (await stored(id))!.signatureId,
      };
      expect(ids, hasLength(3));
    });

    test('une même signature donne le même identifiant d\'un échange à l\'autre', () async {
      await importFromPeer(
        contentIds: ['a'],
        contents: [ExchangedContent(content: _text('a'), signature: _signature())],
      );
      await importFromPeer(
        contentIds: ['b'],
        contents: [ExchangedContent(content: _text('b'), signature: _signature())],
      );

      expect((await stored('a'))!.signatureId, (await stored('b'))!.signatureId);
    });

    test('un identifiant annoncé par le pair ne change pas l\'empreinte', () async {
      await importFromPeer(
        contentIds: ['a', 'b'],
        contents: [
          ExchangedContent(
            content: _text('a'),
            signature: _signature(id: 'un'),
          ),
          ExchangedContent(
            content: _text('b'),
            signature: _signature(id: 'deux'),
          ),
        ],
      );

      expect((await stored('a'))!.signatureId, (await stored('b'))!.signatureId);
    });

    test('passe en anonyme un pseudo, une icône ou une description invalides', () async {
      await importFromPeer(
        contentIds: ['pseudo', 'avatar', 'bio'],
        contents: [
          ExchangedContent(
            content: _text('pseudo'),
            signature: _signature(pseudo: 'a b'),
          ),
          ExchangedContent(
            content: _text('avatar'),
            signature: _signature(avatarText: 'hello'),
          ),
          ExchangedContent(
            content: _text('bio'),
            signature: _signature(bio: 'a' * (maxSignatureBioLength + 1)),
          ),
        ],
      );

      for (final id in ['pseudo', 'avatar', 'bio']) {
        expect((await stored(id))!.signatureId, anonymousSignatureId, reason: id);
      }
    });

    test('borne la vitesse du ghost plutôt que de refuser la signature', () async {
      await importFromPeer(
        contentIds: ['fast', 'slow'],
        contents: [
          ExchangedContent(content: _text('fast'), signature: _signature(ghostSpeed: 500)),
          ExchangedContent(content: _text('slow'), signature: _signature(ghostSpeed: 0)),
        ],
      );

      expect((await storedSignatureOf('fast'))?.ghostSpeed, maxGhostSpeed);
      expect((await storedSignatureOf('slow'))?.ghostSpeed, minGhostSpeed);
    });

    test('remplace une couleur hors de 32 bits par la couleur par défaut', () async {
      await importFromPeer(
        contentIds: ['post'],
        contents: [ExchangedContent(content: _text('post'), signature: _signature(colorArgb: 0x1FFFFFFFF))],
      );

      expect((await storedSignatureOf('post'))?.colorArgb, isNull);
    });
  });

  group('ImportExchangeBundleUsecase : réactions', () {
    setUp(() async {
      await container.read(contentRepositoryProvider).addOne(_text('post', signatureId: 'someone'));
    });

    /// Retourne les réactions enregistrées sur `post`.
    Future<List<Reaction>> storedReactions() {
      return container.read(reactionRepositoryProvider).getAllByContentId('post');
    }

    test('écarte une réaction sur un contenu non demandé', () async {
      final report = await importFromPeer(reactions: [_reaction('r1', contentId: 'post')]);

      expect(report.importedReactions, 0);
      expect(report.rejectedReactions, 1);
      expect(await storedReactions(), isEmpty);
    });

    test('écarte une réaction sur un contenu absent de l\'appareil', () async {
      final report = await importFromPeer(
        reactionContentIds: ['ghost'],
        reactions: [_reaction('r1', contentId: 'ghost')],
      );

      expect(report.rejectedReactions, 1);
    });

    test('accepte les réactions d\'un contenu importé dans le même lot', () async {
      final report = await importFromPeer(
        contentIds: ['new'],
        contents: [ExchangedContent(content: _text('new'))],
        reactions: [_reaction('r1', contentId: 'new')],
      );

      expect(report.importedReactions, 1);
    });

    test('n\'importe qu\'une fois une réaction présente deux fois dans le lot', () async {
      final report = await importFromPeer(
        reactionContentIds: ['post'],
        reactions: [
          _reaction('r1', contentId: 'post'),
          _reaction('r1', contentId: 'post'),
        ],
      );

      expect(report.importedReactions, 1);
      expect(report.rejectedReactions, 1);
    });

    test('écarte une bulle vide, trop longue ou sur plusieurs lignes', () async {
      final report = await importFromPeer(
        reactionContentIds: ['post'],
        reactions: [
          _reaction('empty', contentId: 'post', bubbleText: '   '),
          _reaction('long', contentId: 'post', bubbleText: 'a' * (maxReactionBubbleLength + 1)),
          _reaction('lines', contentId: 'post', bubbleText: 'a\nb'),
        ],
      );

      expect(report.importedReactions, 0);
      expect(report.rejectedReactions, 3);
    });

    test('borne les réactions reçues par contenu à maxReactionsPerContent', () async {
      final report = await importFromPeer(
        reactionContentIds: ['post'],
        reactions: [
          for (var index = 0; index < maxReactionsPerContent + 10; index++) _reaction('r$index', contentId: 'post'),
        ],
      );

      expect(report.importedReactions, maxReactionsPerContent);
      expect(report.rejectedReactions, 10);
      expect(await storedReactions(), hasLength(maxReactionsPerContent));
    });

    test('une version plus ancienne ne remplace pas la version connue', () async {
      await importFromPeer(
        reactionContentIds: ['post'],
        reactions: [_reaction('r1', contentId: 'post', updatedAt: _date, bubbleText: 'récente')],
      );

      await importFromPeer(
        reactionContentIds: ['post'],
        reactions: [
          _reaction('r1', contentId: 'post', updatedAt: _date.subtract(const Duration(days: 1)), bubbleText: 'vieille'),
        ],
      );

      expect((await storedReactions()).single.bubbleText, 'récente');
    });

    test('ramène une date future à la date du jour, pour qu\'une réaction ne reste pas verrouillée', () async {
      await importFromPeer(
        reactionContentIds: ['post'],
        reactions: [_reaction('r1', contentId: 'post', updatedAt: DateTime.now().add(const Duration(days: 365)))],
      );

      expect((await storedReactions()).single.updatedAt.isAfter(DateTime.now()), isFalse);
    });

    test('une réaction écartée n\'empêche pas d\'importer les suivantes', () async {
      final report = await importFromPeer(
        reactionContentIds: ['post'],
        reactions: [
          _reaction('bad', contentId: 'post', bubbleText: ''),
          _reaction('good', contentId: 'post'),
        ],
      );

      expect(report.importedReactions, 1);
    });
  });

  group('cycle complet', () {
    test('un contenu relayé par un intermédiaire garde son texte et sa signature, et gagne un rebond', () async {
      // Premier saut : l'appareil reçoit un contenu d'un auteur inconnu.
      await importFromPeer(
        contentIds: ['post'],
        contents: [
          ExchangedContent(
            content: _text('post', bounce: 2),
            signature: _signature(pseudo: 'auteur'),
          ),
        ],
      );

      // Deuxième saut : il le relaie à son tour, à partir de ce qu'il a stocké.
      final bundle = await buildBundle(const ExchangeRequest(contentIds: ['post'], reactionContentIds: []));

      final relayed = bundle.contents.single;
      expect(relayed.signature?.pseudo, 'auteur');
      expect(relayed.content.bounce, 3);
      expect((relayed.content as TextContent).body, 'Corps');
    });

    test('l\'offre reflète ce qui vient d\'être importé', () async {
      await importFromPeer(
        contentIds: ['post'],
        contents: [ExchangedContent(content: _text('post'))],
      );

      expect((await buildOffer()).contents.map((content) => content.id), ['post']);
    });

    test('après un import, la même offre ne redemande plus rien', () async {
      await importFromPeer(
        contentIds: ['post'],
        contents: [ExchangedContent(content: _text('post'))],
      );
      const offer = ExchangeOffer(contents: [OfferedContent(id: 'post', sizeInBytes: 10, reactionCount: 0)]);

      expect((await select(offer)).contentIds, isEmpty);
    });
  });
}
