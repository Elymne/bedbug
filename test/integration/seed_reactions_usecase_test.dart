import 'package:bedbug/infra/resources/content/content/content.repository.drift.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.config.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.entity.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.repository.drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/content_test_helper.dart';
import '../helpers/drift_test_helper.dart';
import '../helpers/seed_contents_usecase.dart';
import '../helpers/seed_reactions_usecase.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    container = createTestContainer();
  });

  tearDown(() async {
    container.dispose();
  });

  test('pose le nombre demandé de réactions, d\'auteurs tous différents, sur les premiers contenus du fil', () async {
    await container.read(seedContentsUsecaseProvider)(const SeedContentsParams(count: 5, randomSeed: 1));

    await container.read(seedReactionsUsecaseProvider)(
      const SeedReactionsParams(contentCount: 3, reactionsPerContent: 10, randomSeed: 1),
    );

    final feed = [
      for (final detailed
          in (await container
                  .read(contentRepositoryProvider)
                  .getHomeFeedPage(feedStartedAt: DateTime.now(), after: null, limit: 10))
              .items)
        detailed.content,
    ];
    final reactionRepository = container.read(reactionRepositoryProvider);
    for (final (index, content) in feed.indexed) {
      final reactions = await reactionRepository.getAllByContentId(content.id);
      expect(reactions.length, index < 3 ? 10 : 0, reason: 'contenu $index du fil');
      expect(reactions.map((reaction) => reaction.authorId).toSet().length, reactions.length);
      expect(reactions.every((reaction) => Reaction.isValidBubble(reaction.bubbleText)), isTrue);
    }
  });

  test('plafonne le nombre de réactions par contenu', () async {
    await container.read(seedContentsUsecaseProvider)(const SeedContentsParams(count: 1, randomSeed: 1));

    await container.read(seedReactionsUsecaseProvider)(
      const SeedReactionsParams(contentCount: 1, reactionsPerContent: maxReactionsPerContent + 50, randomSeed: 1),
    );

    final content = (await readTestContents(container)).single;
    final reactions = await container.read(reactionRepositoryProvider).getAllByContentId(content.id);
    expect(reactions.length, maxReactionsPerContent);
  });
}
