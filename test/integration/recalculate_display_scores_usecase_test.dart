import 'dart:io';

import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/repositories/content_repository.dart';
import 'package:bedbug/features/content/domain/usecases/recalculate_display_scores_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/save_content_usecase.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/hive_test_helper.dart';

/// Construit un [TextContent] minimal pour les besoins du test, avec un
/// `displayScore` de départ neutre pour bien observer le recalcul.
TextContent _buildContent({
  required String id,
  required ContentOrigin origin,
  required DateTime createdAt,
  int bounce = 0,
}) {
  return TextContent(
    id: id,
    createdAt: createdAt,
    updatedAt: createdAt,
    authorId: 'author',
    senderId: 'sender',
    origin: origin,
    broadcastScore: 0,
    survivalScore: 0,
    displayScore: 0,
    bounce: bounce,
    sizeInBytes: 10,
    title: 'Titre $id',
    body: 'Corps $id',
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

  Future<double> displayScoreOf(ContentRepository repository, String id) async {
    final contents = await repository.getAll();
    return contents.firstWhere((content) => content.id == id).displayScore;
  }

  test('ne modifie jamais le displayScore des contenus owned, quel que soit leur âge, via le vrai repository Hive', () async {
    final repository = container.read(contentRepositoryProvider);
    final saveUsecase = container.read(saveContentUsecaseProvider);
    final usecase = container.read(recalculateDisplayScoresUsecaseProvider);

    final now = DateTime.now();
    await saveUsecase(
      SaveContentParams(content: _buildContent(id: 'owned', origin: ContentOrigin.owned, createdAt: now.subtract(const Duration(days: 3650)))),
    );

    final result = await usecase(const NoParams());

    expect(result.isSuccess, isTrue);
    expect(await displayScoreOf(repository, 'owned'), 0);
  });

  test('le displayScore reste toujours dans [0.0, 1.0], via le vrai repository Hive', () async {
    final repository = container.read(contentRepositoryProvider);
    final saveUsecase = container.read(saveContentUsecaseProvider);
    final usecase = container.read(recalculateDisplayScoresUsecaseProvider);

    final now = DateTime.now();
    await saveUsecase(
      SaveContentParams(content: _buildContent(id: 'ancient', origin: ContentOrigin.public, createdAt: now.subtract(const Duration(days: 3650)))),
    );
    await saveUsecase(
      SaveContentParams(content: _buildContent(id: 'fresh', origin: ContentOrigin.favorited, createdAt: now, bounce: 1000000)),
    );

    await usecase(const NoParams());

    for (final content in await repository.getAll()) {
      expect(content.displayScore, inInclusiveRange(0.0, 1.0));
    }
  });

  test('le displayScore décroît strictement quand le contenu est plus vieux, pour une origin donnée, via le vrai repository Hive', () async {
    final repository = container.read(contentRepositoryProvider);
    final saveUsecase = container.read(saveContentUsecaseProvider);
    final usecase = container.read(recalculateDisplayScoresUsecaseProvider);

    final now = DateTime.now();
    await saveUsecase(
      SaveContentParams(content: _buildContent(id: 'recent', origin: ContentOrigin.public, createdAt: now.subtract(const Duration(hours: 6)))),
    );
    await saveUsecase(
      SaveContentParams(content: _buildContent(id: 'old', origin: ContentOrigin.public, createdAt: now.subtract(const Duration(days: 3)))),
    );

    await usecase(const NoParams());

    final recentScore = await displayScoreOf(repository, 'recent');
    final oldScore = await displayScoreOf(repository, 'old');
    expect(recentScore, greaterThan(oldScore));
  });

  test(
    'à âge égal, favorited reste au moins aussi prioritaire que subscribed, lui-même au moins que public, via le vrai repository Hive',
    () async {
      final repository = container.read(contentRepositoryProvider);
      final saveUsecase = container.read(saveContentUsecaseProvider);
      final usecase = container.read(recalculateDisplayScoresUsecaseProvider);

      final age = DateTime.now().subtract(const Duration(days: 2));
      await saveUsecase(SaveContentParams(content: _buildContent(id: 'favorited', origin: ContentOrigin.favorited, createdAt: age)));
      await saveUsecase(SaveContentParams(content: _buildContent(id: 'subscribed', origin: ContentOrigin.subscribed, createdAt: age)));
      await saveUsecase(SaveContentParams(content: _buildContent(id: 'public', origin: ContentOrigin.public, createdAt: age)));

      await usecase(const NoParams());

      final favoritedScore = await displayScoreOf(repository, 'favorited');
      final subscribedScore = await displayScoreOf(repository, 'subscribed');
      final publicScore = await displayScoreOf(repository, 'public');
      expect(favoritedScore, greaterThanOrEqualTo(subscribedScore));
      expect(subscribedScore, greaterThanOrEqualTo(publicScore));
    },
  );

  test('augmenter le bounce ne peut jamais faire baisser le displayScore, via le vrai repository Hive', () async {
    final repository = container.read(contentRepositoryProvider);
    final saveUsecase = container.read(saveContentUsecaseProvider);
    final usecase = container.read(recalculateDisplayScoresUsecaseProvider);

    final createdAt = DateTime.now().subtract(const Duration(days: 1));
    await saveUsecase(SaveContentParams(content: _buildContent(id: 'lowBounce', origin: ContentOrigin.public, createdAt: createdAt)));
    await saveUsecase(
      SaveContentParams(content: _buildContent(id: 'highBounce', origin: ContentOrigin.public, createdAt: createdAt, bounce: 50)),
    );

    await usecase(const NoParams());

    final lowBounceScore = await displayScoreOf(repository, 'lowBounce');
    final highBounceScore = await displayScoreOf(repository, 'highBounce');
    expect(highBounceScore, greaterThanOrEqualTo(lowBounceScore));
  });
}
