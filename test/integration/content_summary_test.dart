import 'dart:math';

import 'package:bedbug/infra/resources/content/content/content.entity.summary.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.drift.dart';
import 'package:bedbug/infra/resources/content/content/content_origin.enum.dart';
import 'package:bedbug/infra/resources/content/content/text_content.entity.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.entity.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.repository.drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/drift_test_helper.dart';

/// Construit un contenu reçu d'identifiant [id].
///
/// - [id] : identifiant du contenu.
/// - [broadcastScore] : priorité de diffusion.
/// - [survivalScore] : priorité de conservation.
/// - [sizeInBytes] : poids déclaré du contenu.
/// - [origin] : provenance du contenu.
TextContent _buildContent(
  String id, {
  double broadcastScore = 0,
  double survivalScore = 0,
  int sizeInBytes = 10,
  ContentOrigin origin = ContentOrigin.public,
}) {
  return TextContent(
    id: id,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    signatureId: 'pair',
    flair: 'test',
    origin: origin,
    broadcastScore: broadcastScore,
    survivalScore: survivalScore,
    displayScore: 0,
    bounce: 0,
    sizeInBytes: sizeInBytes,
    title: 'Titre $id',
    body: 'Corps $id',
  );
}

/// Construit une réaction sur [contentId], mise à jour à [updatedAt].
///
/// - [id] : identifiant de la réaction.
/// - [contentId] : contenu auquel elle est rattachée.
/// - [updatedAt] : date de mise à jour.
Reaction _buildReaction(String id, String contentId, DateTime updatedAt) {
  return Reaction(
    id: id,
    createdAt: updatedAt,
    updatedAt: updatedAt,
    contentId: contentId,
    authorId: id,
    avatarFrames: const ['(◕‿◕)'],
    bubbleText: 'ok',
  );
}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = createTestContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('un résumé compte les réactions et retient la plus récente, à la milliseconde', () async {
    final latest = DateTime(2026, 3, 1, 12, 0, 0, 456);
    await container.read(contentRepositoryProvider).addMany([
      _buildContent('avec', sizeInBytes: 123),
      _buildContent('sans', sizeInBytes: 7),
    ]);
    await container.read(reactionRepositoryProvider).addMany([
      _buildReaction('r1', 'avec', DateTime(2026, 1)),
      _buildReaction('r2', 'avec', latest),
      _buildReaction('r3', 'avec', DateTime(2026, 2)),
    ]);

    final summaries = await container.read(contentRepositoryProvider).getSummariesByIds({'avec', 'sans', 'absent'});

    expect(
      summaries,
      unorderedEquals([
        ContentSummary(contentId: 'avec', sizeInBytes: 123, reactionCount: 3, latestReactionAt: latest),
        const ContentSummary(contentId: 'sans', sizeInBytes: 7, reactionCount: 0, latestReactionAt: null),
      ]),
    );
  });

  test('les plus diffusables passent en tête, du plus fort au plus faible', () async {
    await container.read(contentRepositoryProvider).addMany([
      _buildContent('moyen', broadcastScore: 0.5),
      _buildContent('fort', broadcastScore: 0.9),
      _buildContent('faible', broadcastScore: 0.1),
    ]);

    final top = await container.read(contentRepositoryProvider).getTopSummariesByBroadcastScore(2);

    expect(top.map((summary) => summary.contentId), ['fort', 'moyen']);
  });

  test('le tirage au hasard écarte les exclus et se reproduit avec la même graine', () async {
    await container.read(contentRepositoryProvider).addMany([
      for (var index = 0; index < 20; index++) _buildContent('c$index'),
    ]);
    final repository = container.read(contentRepositoryProvider);

    final first = await repository.getRandomSummariesExcluding(5, {'c0', 'c1'}, Random(3));
    final second = await repository.getRandomSummariesExcluding(5, {'c0', 'c1'}, Random(3));

    expect(first, hasLength(5));
    expect(first.map((summary) => summary.contentId), isNot(contains('c0')));
    expect(first.map((summary) => summary.contentId), isNot(contains('c1')));
    expect(first, second);
  });

  test('les candidats à la suppression sont les contenus reçus, du moins au plus digne d\'être gardé', () async {
    await container.read(contentRepositoryProvider).addMany([
      _buildContent('mien', survivalScore: 0, origin: ContentOrigin.owned),
      _buildContent('fort', survivalScore: 0.9),
      _buildContent('faible', survivalScore: 0.1),
    ]);

    final candidates = await container.read(contentRepositoryProvider).getReceivedSummariesBySurvival(10);

    expect(candidates.map((summary) => summary.contentId), ['faible', 'fort']);
  });
}
