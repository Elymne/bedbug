import 'dart:io';

import 'package:bedbug/features/content/domain/entities/reaction.dart';
import 'package:bedbug/features/content/domain/usecases/save_reaction_usecase.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_reaction_repository.dart';
import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/hive_test_helper.dart';

/// Construit une réaction de test sur le contenu `content`.
///
/// - [id] : identifiant de la réaction.
/// - [authorId] : signature qui réagit.
/// - [updatedAt] : date de mise à jour, qui départage deux réactions d'un même auteur.
/// - [avatarText] : bedbug de la réaction.
/// - [bubbleText] : bulle de texte optionnelle.
Reaction _reaction({
  required String id,
  required String authorId,
  required DateTime updatedAt,
  String avatarText = '(◕‿◕)',
  String? bubbleText,
}) {
  return Reaction(
    id: id,
    createdAt: updatedAt,
    updatedAt: updatedAt,
    contentId: 'content',
    authorId: authorId,
    avatarText: avatarText,
    bubbleText: bubbleText,
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

  test('une nouvelle réaction du même auteur remplace la précédente', () async {
    final saveUsecase = container.read(saveReactionUsecaseProvider);
    final repository = container.read(reactionRepositoryProvider);

    await saveUsecase(
      SaveReactionParams(
        reaction: _reaction(id: 'old', authorId: 'alice', updatedAt: DateTime(2026)),
      ),
    );
    await saveUsecase(
      SaveReactionParams(
        reaction: _reaction(id: 'new', authorId: 'alice', updatedAt: DateTime(2026, 2), bubbleText: 'mdr'),
      ),
    );

    final reactions = await repository.getAllByContentId('content');
    expect(reactions.map((reaction) => reaction.id), ['new']);
    expect(reactions.single.bubbleText, 'mdr');
  });

  test('une réaction plus ancienne que celle déjà enregistrée pour cet auteur est ignorée', () async {
    final saveUsecase = container.read(saveReactionUsecaseProvider);
    final repository = container.read(reactionRepositoryProvider);

    await saveUsecase(
      SaveReactionParams(
        reaction: _reaction(id: 'new', authorId: 'alice', updatedAt: DateTime(2026, 2)),
      ),
    );
    final result = await saveUsecase(
      SaveReactionParams(
        reaction: _reaction(id: 'old', authorId: 'alice', updatedAt: DateTime(2026)),
      ),
    );

    expect(result.right?.id, 'new');
    final reactions = await repository.getAllByContentId('content');
    expect(reactions.map((reaction) => reaction.id), ['new']);
  });

  test('refuse un bedbug contenant un mot ou une bulle trop longue', () async {
    final saveUsecase = container.read(saveReactionUsecaseProvider);
    final repository = container.read(reactionRepositoryProvider);

    final wordResult = await saveUsecase(
      SaveReactionParams(
        reaction: _reaction(id: 'a', authorId: 'alice', updatedAt: DateTime(2026), avatarText: 'coucou'),
      ),
    );
    final longBubbleResult = await saveUsecase(
      SaveReactionParams(
        reaction: _reaction(
          id: 'b',
          authorId: 'bob',
          updatedAt: DateTime(2026),
          bubbleText: 'a' * (maxReactionBubbleLength + 1),
        ),
      ),
    );

    expect(wordResult.left, SaveReactionFailure.invalidReaction);
    expect(longBubbleResult.left, SaveReactionFailure.invalidReaction);
    expect(await repository.getAllByContentId('content'), isEmpty);
  });

  test('une bulle vide ou faite d\'espaces est enregistrée comme absente', () async {
    final saveUsecase = container.read(saveReactionUsecaseProvider);

    final result = await saveUsecase(
      SaveReactionParams(
        reaction: _reaction(id: 'a', authorId: 'alice', updatedAt: DateTime(2026), bubbleText: '   '),
      ),
    );

    expect(result.right?.bubbleText, isNull);
  });

  test('ne garde que les réactions les plus récentes au-delà du plafond par contenu', () async {
    final saveUsecase = container.read(saveReactionUsecaseProvider);
    final repository = container.read(reactionRepositoryProvider);

    for (var index = 0; index <= maxReactionsPerContent; index++) {
      await saveUsecase(
        SaveReactionParams(
          reaction: _reaction(
            id: 'reaction-$index',
            authorId: 'author-$index',
            updatedAt: DateTime(2026).add(Duration(minutes: index)),
          ),
        ),
      );
    }

    final reactions = await repository.getAllByContentId('content');
    expect(reactions.length, maxReactionsPerContent);
    expect(reactions.map((reaction) => reaction.id), isNot(contains('reaction-0')));
  });

  test('ramène l\'intensité du ghost dans ses bornes et conserve la couleur choisie', () async {
    final saveUsecase = container.read(saveReactionUsecaseProvider);
    final repository = container.read(reactionRepositoryProvider);

    await saveUsecase(
      SaveReactionParams(
        reaction: Reaction(
          id: 'a',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          contentId: 'content',
          authorId: 'alice',
          avatarText: '(◕‿◕)',
          colorArgb: 0xFF51C2FF,
          ghostSpeed: 99,
        ),
      ),
    );

    final saved = (await repository.getAllByContentId('content')).single;
    expect(saved.ghostSpeed, maxGhostSpeed);
    expect(saved.colorArgb, 0xFF51C2FF);
  });
}
