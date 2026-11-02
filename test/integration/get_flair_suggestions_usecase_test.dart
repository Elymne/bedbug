import 'dart:io';

import 'package:bedbug/resources/content/content/content.repository.hive.dart';
import 'package:bedbug/resources/content/content/content_origin.enum.dart';
import 'package:bedbug/resources/content/content/text_content.entity.dart';
import 'package:bedbug/usecases/feed/get_flair_suggestions/get_flair_suggestions.config.dart';
import 'package:bedbug/usecases/feed/get_flair_suggestions/get_flair_suggestions.params.dart';
import 'package:bedbug/usecases/feed/get_flair_suggestions/get_flair_suggestions.usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/hive_test_helper.dart';

/// Construit un contenu texte portant le flair [flair].
///
/// - [id] : identifiant du contenu.
/// - [flair] : flair du contenu.
TextContent _buildContent(String id, String flair) {
  return TextContent(
    id: id,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    signatureId: 'local',
    flair: flair,
    origin: ContentOrigin.owned,
    broadcastScore: 1,
    survivalScore: 1,
    displayScore: 1,
    bounce: 0,
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

  test('regroupe les flairs par nombre de contenus, puis par ordre alphabétique', () async {
    await container.read(contentRepositoryProvider).addMany([
      _buildContent('a', 'france'),
      _buildContent('b', 'fromage'),
      _buildContent('c', 'fromage'),
      _buildContent('d', 'football'),
      _buildContent('e', 'cuisine'),
    ]);

    final result = await container.read(getFlairSuggestionsUsecaseProvider)(
      const GetFlairSuggestionsParams(input: '/F'),
    );

    final suggestions = result.right!;
    expect(suggestions.map((suggestion) => suggestion.flair), ['fromage', 'football', 'france']);
    expect(suggestions.first.contentCount, 2);
  });

  test('limite le nombre de suggestions', () async {
    await container.read(contentRepositoryProvider).addMany([
      for (var index = 0; index < maxFlairSuggestions + 3; index++) _buildContent('c$index', 'flair$index'),
    ]);

    final result = await container.read(getFlairSuggestionsUsecaseProvider)(
      const GetFlairSuggestionsParams(input: 'flair'),
    );

    expect(result.right, hasLength(maxFlairSuggestions));
  });
}
