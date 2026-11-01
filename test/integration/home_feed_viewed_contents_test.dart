import 'dart:io';

import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/repositories/storage_repository.dart';
import 'package:bedbug/features/content/domain/usecases/enforce_storage_limit_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/get_home_feed_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/mark_content_viewed_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/save_content_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/save_storage_limit_usecase.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_viewed_content_repository.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/hive_test_helper.dart';

/// Construit un contenu d'identifiant [id].
///
/// - [id] : identifiant du contenu.
/// - [displayScore] : priorité d'affichage.
/// - [origin] : provenance du contenu.
/// - [body] : corps du contenu, dont dépend son poids.
TextContent _buildContent(
  String id,
  double displayScore, {
  ContentOrigin origin = ContentOrigin.public,
  String body = 'Corps',
}) {
  return TextContent(
    id: id,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    signatureId: 'local',
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

  test('les contenus pas encore vus passent devant, chaque groupe gardant l\'ordre du score', () async {
    await saveAll([_buildContent('vu-haut', 9), _buildContent('vu-bas', 5), _buildContent('neuf-haut', 3)]);
    await saveAll([_buildContent('neuf-bas', 1)]);
    await markViewed('vu-haut');
    await markViewed('vu-bas');

    final feed = (await container.read(getHomeFeedUsecaseProvider)(const NoParams())).right!;

    expect(feed.contents.map((content) => content.id), ['neuf-haut', 'neuf-bas', 'vu-haut', 'vu-bas']);
    expect(feed.unviewedContentIds, {'neuf-haut', 'neuf-bas'});
  });

  test('les contenus de l\'utilisateur ne comptent jamais comme nouveaux', () async {
    await saveAll([_buildContent('mien', 9, origin: ContentOrigin.owned), _buildContent('recu', 1)]);

    final feed = (await container.read(getHomeFeedUsecaseProvider)(const NoParams())).right!;

    expect(feed.contents.map((content) => content.id), ['recu', 'mien']);
    expect(feed.unviewedContentIds, {'recu'});
  });

  test('la mémoire survit à un nouveau chargement du fil', () async {
    await saveAll([_buildContent('a', 1)]);
    await markViewed('a');

    final secondContainer = ProviderContainer();
    addTearDown(secondContainer.dispose);
    final feed = (await secondContainer.read(getHomeFeedUsecaseProvider)(const NoParams())).right!;

    expect(feed.unviewedContentIds, isEmpty);
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
