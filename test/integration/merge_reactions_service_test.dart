import 'package:bedbug/infra/resources/content/reaction/reaction.config.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.entity.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.repository.drift.dart';
import 'package:bedbug/logic/services/reaction/merge_reactions/merge_reactions.failure.dart';
import 'package:bedbug/logic/services/reaction/merge_reactions/merge_reactions.params.dart';
import 'package:bedbug/logic/services/reaction/merge_reactions/merge_reactions.service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/content_test_helper.dart';
import '../helpers/drift_test_helper.dart';

/// Construit une réaction de test.
///
/// - [id] : identifiant de la réaction.
/// - [authorId] : signature qui réagit.
/// - [updatedAt] : date de mise à jour, qui départage deux versions et fixe l'ordre du plafond.
/// - [contentId] : contenu de la réaction.
/// - [bubbleText] : bulle de texte, vide pour une réaction invalide.
Reaction _reaction({
  required String id,
  required String authorId,
  required DateTime updatedAt,
  String contentId = 'content',
  String bubbleText = 'mdr',
}) {
  return Reaction(
    id: id,
    createdAt: updatedAt,
    updatedAt: updatedAt,
    contentId: contentId,
    authorId: authorId,
    avatarFrames: const ['(◕‿◕)'],
    bubbleText: bubbleText,
  );
}

void main() {
  late ProviderContainer container;

  setUp(() async {
    container = createTestContainer();
    await addTestContents(container, ['content', 'other-content']);
  });

  tearDown(() async {
    container.dispose();
  });

  test('deux versions d\'un même auteur dans un lot : la plus récente gagne, quel que soit l\'ordre', () async {
    final service = container.read(mergeReactionsServiceProvider);

    final result = await service(
      MergeReactionsParams(
        reactions: [
          _reaction(id: 'v2', authorId: 'alice', updatedAt: DateTime(2026, 2)),
          _reaction(id: 'v1', authorId: 'alice', updatedAt: DateTime(2026)),
        ],
      ),
    );

    expect([for (final kept in result.right!) kept?.id], ['v2', 'v2']);
    final stored = await container.read(reactionRepositoryProvider).getAllByContentId('content');
    expect([for (final reaction in stored) reaction.id], ['v2']);
  });

  test('une réaction invalide est écartée sans empêcher les autres du lot', () async {
    final service = container.read(mergeReactionsServiceProvider);

    final result = await service(
      MergeReactionsParams(
        reactions: [
          _reaction(id: 'ok-1', authorId: 'alice', updatedAt: DateTime(2026)),
          _reaction(id: 'vide', authorId: 'bob', updatedAt: DateTime(2026), bubbleText: '   '),
          _reaction(id: 'ok-2', authorId: 'carol', updatedAt: DateTime(2026), contentId: 'other-content'),
        ],
      ),
    );

    expect([for (final kept in result.right!) kept?.id], ['ok-1', null, 'ok-2']);
    final stored = await container.read(reactionRepositoryProvider).getAllByContentIds({'content', 'other-content'});
    expect({for (final reaction in stored) reaction.id}, {'ok-1', 'ok-2'});
  });

  test('le plafond s\'applique au lot entier, réactions déjà en base comprises', () async {
    final start = DateTime(2026);
    await insertTestReactions(container, [
      for (var index = 0; index < maxReactionsPerContent - 2; index++)
        _reaction(
          id: 'base-$index',
          authorId: 'base-$index',
          updatedAt: start.add(Duration(minutes: index)),
        ),
    ]);
    final service = container.read(mergeReactionsServiceProvider);

    final result = await service(
      MergeReactionsParams(
        reactions: [
          for (var index = 0; index < 5; index++)
            _reaction(
              id: 'new-$index',
              authorId: 'new-$index',
              updatedAt: DateTime(2027).add(Duration(minutes: index)),
            ),
          _reaction(id: 'trop-vieux', authorId: 'vieux', updatedAt: DateTime(2000)),
        ],
      ),
    );

    expect(result.isSuccess, isTrue);
    final stored = await container.read(reactionRepositoryProvider).getAllByContentId('content');
    final storedIds = {for (final reaction in stored) reaction.id};
    expect(stored.length, maxReactionsPerContent);
    expect(storedIds, containsAll(['new-0', 'new-4']));
    // Les trois plus anciennes de la base cèdent leur place, et la réaction plus vieille que tout n'entre pas.
    expect(storedIds, isNot(contains('base-0')));
    expect(storedIds, isNot(contains('base-2')));
    expect(storedIds, contains('base-3'));
    expect(storedIds, isNot(contains('trop-vieux')));
  });

  test('un échec d\'écriture n\'écrit aucune réaction du lot', () async {
    final service = container.read(mergeReactionsServiceProvider);

    final result = await service(
      MergeReactionsParams(
        reactions: [
          _reaction(id: 'valide', authorId: 'alice', updatedAt: DateTime(2026)),
          _reaction(id: 'orpheline', authorId: 'bob', updatedAt: DateTime(2026), contentId: 'absent'),
        ],
      ),
    );

    expect(result.left, MergeReactionsFailure.storageError);
    expect(await container.read(reactionRepositoryProvider).getAllByContentId('content'), isEmpty);
  });
}
