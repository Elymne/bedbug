import 'dart:io';

import 'package:bedbug/features/content/domain/entities/reaction.dart';
import 'package:bedbug/features/content/domain/extensions/reaction_text_extension.dart';
import 'package:bedbug/features/content/domain/usecases/seed_contents_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/seed_reactions_usecase.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_reaction_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/hive_test_helper.dart';

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

  test('pose le nombre demandé de réactions, d\'auteurs tous différents, sur les premiers contenus du fil', () async {
    await container.read(seedContentsUsecaseProvider)(const SeedContentsParams(count: 5, randomSeed: 1));

    await container.read(seedReactionsUsecaseProvider)(
      const SeedReactionsParams(contentCount: 3, reactionsPerContent: 10, randomSeed: 1),
    );

    final feed = await container.read(contentRepositoryProvider).getAllOrderedByDisplayScoreDesc();
    final reactionRepository = container.read(reactionRepositoryProvider);
    for (final (index, content) in feed.indexed) {
      final reactions = await reactionRepository.getAllByContentId(content.id);
      expect(reactions.length, index < 3 ? 10 : 0, reason: 'contenu $index du fil');
      expect(reactions.map((reaction) => reaction.authorId).toSet().length, reactions.length);
      expect(reactions.every((reaction) => reaction.bubbleText.isValidReactionBubble), isTrue);
    }
  });

  test('plafonne le nombre de réactions par contenu', () async {
    await container.read(seedContentsUsecaseProvider)(const SeedContentsParams(count: 1, randomSeed: 1));

    await container.read(seedReactionsUsecaseProvider)(
      const SeedReactionsParams(contentCount: 1, reactionsPerContent: maxReactionsPerContent + 50, randomSeed: 1),
    );

    final content = (await container.read(contentRepositoryProvider).getAll()).single;
    final reactions = await container.read(reactionRepositoryProvider).getAllByContentId(content.id);
    expect(reactions.length, maxReactionsPerContent);
  });
}
