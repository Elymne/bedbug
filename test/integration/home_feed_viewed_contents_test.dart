import 'package:bedbug/core/domain/cursor_page.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/infra/resources/content/content/content.config.dart';
import 'package:bedbug/infra/resources/content/content/content.entity.dart';
import 'package:bedbug/infra/resources/content/content/content.entity.detailed.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.drift.dart';
import 'package:bedbug/infra/resources/content/content/content_origin.enum.dart';
import 'package:bedbug/infra/resources/content/content/text_content.entity.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.entity.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.repository.drift.dart';
import 'package:bedbug/infra/resources/content/storage/storage.config.dart';
import 'package:bedbug/infra/resources/content/viewed_content/viewed_content.repository.drift.dart';
import 'package:bedbug/infra/resources/signature/signature/signature.config.dart';
import 'package:bedbug/infra/resources/signature/signature/signature.entity.dart';
import 'package:bedbug/infra/resources/signature/signature/signature.repository.drift.dart';
import 'package:bedbug/logic/usecases/content/save_content/save_content.params.dart';
import 'package:bedbug/logic/usecases/content/save_content/save_content.usecase.dart';
import 'package:bedbug/logic/usecases/feed/get_home_feed/get_home_feed.params.dart';
import 'package:bedbug/logic/usecases/feed/get_home_feed/get_home_feed.usecase.dart';
import 'package:bedbug/logic/usecases/feed/mark_content_viewed/mark_content_viewed.params.dart';
import 'package:bedbug/logic/usecases/feed/mark_content_viewed/mark_content_viewed.usecase.dart';
import 'package:bedbug/logic/usecases/storage/enforce_storage_limit/enforce_storage_limit.usecase.dart';
import 'package:bedbug/logic/usecases/storage/save_storage_limit/save_storage_limit.params.dart';
import 'package:bedbug/logic/usecases/storage/save_storage_limit/save_storage_limit.usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/drift_test_helper.dart';

/// Construit un contenu d'identifiant [id].
///
/// - [id] : identifiant du contenu.
/// - [displayScore] : priorité d'affichage.
/// - [origin] : provenance du contenu.
/// - [body] : corps du contenu, dont dépend son poids.
/// - [signatureId] : signature de l'auteur.
TextContent _buildContent(
  String id,
  double displayScore, {
  ContentOrigin origin = ContentOrigin.public,
  String body = 'Corps',
  String signatureId = 'local',
}) {
  return TextContent(
    id: id,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    signatureId: signatureId,
    flair: 'test',
    origin: origin,
    broadcastScore: 1,
    survivalScore: displayScore,
    displayScore: displayScore,
    bounce: 0,
    sizeInBytes: 1024,
    title: 'Titre $id',
    body: body,
  );
}

/// Construit une réaction de [authorId] sur [contentId].
///
/// - [id] : identifiant de la réaction.
/// - [contentId] : contenu auquel elle est rattachée.
/// - [authorId] : auteur de la réaction.
Reaction _buildReaction(String id, String contentId, String authorId) {
  return Reaction(
    id: id,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    contentId: contentId,
    authorId: authorId,
    avatarFrames: const ['(◕‿◕)'],
    bubbleText: 'ok',
  );
}

/// Laisse passer quelques millisecondes, pour que deux dates relevées de part et d'autre diffèrent.
Future<void> _tick() async {
  await Future<void>.delayed(const Duration(milliseconds: 5));
}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = createTestContainer();
  });

  tearDown(() {
    container.dispose();
  });

  /// Enregistre [contents] avec le vrai repository.
  Future<void> saveAll(List<Content> contents) async {
    for (final content in contents) {
      await container.read(saveContentUsecaseProvider)(SaveContentParams(content: content));
    }
  }

  /// Mémorise le contenu [id] comme vu.
  Future<void> markViewed(String id) async {
    await container.read(markContentViewedUsecaseProvider)(MarkContentViewedParams(contentId: id));
  }

  /// Lit une page du fil de la session [feedStartedAt], après [after].
  Future<CursorPage<ContentDetailed>> readPage(DateTime feedStartedAt, {String? after}) async {
    final result = await container.read(getHomeFeedUsecaseProvider)(
      GetHomeFeedParams(feedStartedAt: feedStartedAt, after: after),
    );
    return result.right!;
  }

  /// Lit tout le fil de la session [feedStartedAt], page par page, en appelant [betweenPages] entre deux pages.
  Future<List<ContentDetailed>> readAllPages(
    DateTime feedStartedAt, {
    Future<void> Function(int pageIndex)? betweenPages,
  }) async {
    final items = <ContentDetailed>[];
    String? after;
    var pageIndex = 0;
    do {
      final page = await readPage(feedStartedAt, after: after);
      items.addAll(page.items);
      after = page.nextCursor;
      if (after != null && betweenPages != null) {
        await betweenPages(pageIndex);
      }
      pageIndex++;
    } while (after != null);
    return items;
  }

  /// Retourne les identifiants des contenus nouveaux de [items] : ni à l'utilisateur, ni vus.
  Set<String> unviewedIdsOf(List<ContentDetailed> items) {
    return {
      for (final detailed in items)
        if (!detailed.content.isOwned && !detailed.isViewed) detailed.content.id,
    };
  }

  test('les contenus pas encore vus passent devant, chaque groupe gardant l\'ordre du score', () async {
    await saveAll([_buildContent('vu-haut', 9), _buildContent('vu-bas', 5), _buildContent('neuf-haut', 3)]);
    await saveAll([_buildContent('neuf-bas', 1)]);
    await markViewed('vu-haut');
    await markViewed('vu-bas');

    final page = await readPage(DateTime.now());

    expect(page.items.map((detailed) => detailed.content.id), ['neuf-haut', 'neuf-bas', 'vu-haut', 'vu-bas']);
    expect(unviewedIdsOf(page.items), {'neuf-haut', 'neuf-bas'});
    expect(page.hasMore, isFalse);
  });

  test('les contenus de l\'utilisateur ne comptent jamais comme nouveaux', () async {
    await saveAll([_buildContent('mien', 9, origin: ContentOrigin.owned), _buildContent('recu', 1)]);

    final page = await readPage(DateTime.now());

    expect(page.items.map((detailed) => detailed.content.id), ['recu', 'mien']);
    expect(unviewedIdsOf(page.items), {'recu'});
  });

  test('la mémoire survit à un nouveau chargement du fil', () async {
    await saveAll([_buildContent('a', 1)]);
    await markViewed('a');

    await readPage(DateTime.now());
    final reloaded = await readPage(DateTime.now());

    expect(unviewedIdsOf(reloaded.items), isEmpty);
  });

  test(
    'chaque contenu arrive avec la signature de son auteur, son nombre de réactions et sa trace d\'affichage',
    () async {
      final now = DateTime(2026);
      await container
          .read(signatureRepositoryProvider)
          .saveLocal(Signature(id: localSignatureId, createdAt: now, updatedAt: now, pseudo: 'Moi'));
      await container.read(signatureRepositoryProvider).saveMany([
        Signature(id: 'peer-1', createdAt: now, updatedAt: now, pseudo: 'Pair'),
      ]);
      await saveAll([
        _buildContent('local', 3, origin: ContentOrigin.owned),
        _buildContent('pair', 2, signatureId: 'peer-1'),
        _buildContent('anonyme', 1, signatureId: anonymousSignatureId),
        _buildContent('inconnu', 0, signatureId: 'peer-disparu'),
      ]);
      await container.read(reactionRepositoryProvider).addMany([
        _buildReaction('r1', 'pair', 'a'),
        _buildReaction('r2', 'pair', 'b'),
        _buildReaction('r3', 'local', 'a'),
      ]);
      await markViewed('pair');

      final page = await readPage(DateTime.now());
      final byId = {for (final detailed in page.items) detailed.content.id: detailed};

      expect(byId['local']!.signature?.pseudo, 'Moi');
      expect(byId['pair']!.signature?.pseudo, 'Pair');
      expect(byId['anonyme']!.signature, isNull);
      expect(byId['inconnu']!.signature, isNull);
      expect(byId['pair']!.reactionCount, 2);
      expect(byId['local']!.reactionCount, 1);
      expect(byId['anonyme']!.reactionCount, 0);
      expect(byId['pair']!.isViewed, isTrue);
      expect(byId['anonyme']!.isViewed, isFalse);
    },
  );

  test('les pages s\'enchaînent sans doublon ni trou, groupes compris, scores égaux compris', () async {
    final contents = [
      for (var index = 0; index < contentPageSize * 2 + 7; index++)
        _buildContent('c${index.toString().padLeft(3, '0')}', (index % 4).toDouble()),
    ];
    await container.read(contentRepositoryProvider).addMany(contents);
    for (var index = 0; index < contents.length; index += 3) {
      await markViewed(contents[index].id);
    }
    await _tick();

    final feedStartedAt = DateTime.now();
    final paged = await readAllPages(feedStartedAt);
    final single = await container
        .read(contentRepositoryProvider)
        .getHomeFeedPage(feedStartedAt: feedStartedAt, after: null, limit: contents.length);

    expect(paged.length, contents.length);
    expect(paged.map((detailed) => detailed.content.id).toSet().length, contents.length);
    expect(
      paged.map((detailed) => detailed.content.id).toList(),
      single.items.map((detailed) => detailed.content.id).toList(),
    );
    final firstReadIndex = paged.indexWhere((detailed) => detailed.isViewed);
    expect(paged.skip(firstReadIndex).every((detailed) => detailed.isViewed), isTrue);
  });

  test('marquer vu ou recevoir des contenus pendant le défilement ne change pas la session', () async {
    final contents = [
      for (var index = 0; index < contentPageSize * 3; index++) _buildContent('c$index', (index % 7).toDouble()),
    ];
    await container.read(contentRepositoryProvider).addMany(contents);
    await _tick();
    final feedStartedAt = DateTime.now();
    final reference = await readAllPages(feedStartedAt);
    await _tick();

    final scrolled = await readAllPages(
      feedStartedAt,
      betweenPages: (pageIndex) async {
        // Tout ce qui vient d'être affiché est marqué vu, et un pair envoie de nouveaux contenus.
        for (final content in contents) {
          await markViewed(content.id);
        }
        await saveAll([_buildContent('recu-$pageIndex-a', 10), _buildContent('recu-$pageIndex-b', 0)]);
      },
    );

    expect(
      scrolled.map((detailed) => detailed.content.id).toList(),
      reference.map((detailed) => detailed.content.id).toList(),
    );
    expect(scrolled.every((detailed) => !detailed.isViewed), isTrue);

    final nextSession = await readAllPages(DateTime.now());
    expect(nextSession.length, contents.length + 4);
    expect(nextSession.first.content.id, 'recu-0-a');
  });

  test('un contenu supprimé par le nettoyage du stockage quitte la mémoire', () async {
    final heavyBody = 'x' * (600 * 1024);
    await saveAll([_buildContent('faible', 1, body: heavyBody), _buildContent('fort', 9, body: heavyBody)]);
    await markViewed('faible');
    await markViewed('fort');
    await container.read(saveStorageLimitUsecaseProvider)(
      const SaveStorageLimitParams(maxSizeInBytes: bytesPerMegabyte),
    );

    final removedCount = (await container.read(enforceStorageLimitUsecaseProvider)(const NoParams())).right;

    expect(removedCount, 1);
    final viewedIds = await container.read(viewedContentRepositoryProvider).getAllIds();
    expect(viewedIds, {'fort'});
  });
}
