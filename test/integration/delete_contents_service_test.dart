import 'package:bedbug/infra/resources/content/comment/comment.config.dart';
import 'package:bedbug/infra/resources/content/comment/comment.entity.dart';
import 'package:bedbug/infra/resources/content/comment/comment.repository.drift.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.drift.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.entity.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.repository.drift.dart';
import 'package:bedbug/infra/resources/content/seen_content/seen_content.repository.drift.dart';
import 'package:bedbug/infra/resources/content/viewed_content/viewed_content.entity.dart';
import 'package:bedbug/infra/resources/content/viewed_content/viewed_content.repository.drift.dart';
import 'package:bedbug/logic/services/content/delete_contents/delete_contents.params.dart';
import 'package:bedbug/logic/services/content/delete_contents/delete_contents.service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/content_test_helper.dart';
import '../helpers/drift_test_helper.dart';

void main() {
  late ProviderContainer container;
  final date = DateTime(2026);

  setUp(() async {
    container = createTestContainer();
    await addTestContents(container, ['supprime', 'garde']);
    for (final contentId in ['supprime', 'garde']) {
      await insertTestReactions(container, [
        Reaction(
          id: 'reaction-$contentId',
          createdAt: date,
          updatedAt: date,
          contentId: contentId,
          authorId: 'pair',
          avatarFrames: const ['(◕‿◕)'],
          bubbleText: 'ok',
        ),
      ]);
      await container
          .read(commentRepositoryProvider)
          .addOneKeepingLatest(
            Comment(
              id: 'comment-$contentId',
              createdAt: date,
              updatedAt: date,
              contentId: contentId,
              signatureId: 'pair',
              body: 'Trop bien',
            ),
            maxPerContent: maxCommentsPerContent,
          );
      await container
          .read(viewedContentRepositoryProvider)
          .addOne(ViewedContent(id: contentId, createdAt: date, updatedAt: date));
    }
  });

  tearDown(() {
    container.dispose();
  });

  test('supprime le contenu avec ses réactions, commentaires et trace d\'affichage, et seulement lui', () async {
    final result = await container.read(deleteContentsServiceProvider)(
      const DeleteContentsParams(contentIds: ['supprime']),
    );

    expect(result.isSuccess, isTrue);
    expect(await container.read(contentRepositoryProvider).getById('supprime'), isNull);
    expect(await container.read(reactionRepositoryProvider).getAllByContentId('supprime'), isEmpty);
    expect(await container.read(commentRepositoryProvider).getAllByContentId('supprime'), isEmpty);
    expect(await readTestViewedIds(container), {'garde'});
    expect(await container.read(reactionRepositoryProvider).getAllByContentId('garde'), hasLength(1));
    expect(await container.read(commentRepositoryProvider).getAllByContentId('garde'), hasLength(1));
  });

  test('la trace de réception survit à la suppression, pour qu\'un pair ne le renvoie pas', () async {
    await container.read(deleteContentsServiceProvider)(const DeleteContentsParams(contentIds: ['supprime']));

    final seen = await container.read(seenContentRepositoryProvider).getSeenAmong({'supprime', 'garde'});

    expect(seen, {'supprime'});
  });

  test('un contenu déjà absent est simplement mémorisé comme vu', () async {
    final result = await container.read(deleteContentsServiceProvider)(
      const DeleteContentsParams(contentIds: ['absent']),
    );

    expect(result.isSuccess, isTrue);
    expect(await container.read(seenContentRepositoryProvider).getSeenAmong({'absent'}), {'absent'});
    expect(await container.read(contentRepositoryProvider).getExistingIds({'supprime', 'garde'}), hasLength(2));
  });
}
