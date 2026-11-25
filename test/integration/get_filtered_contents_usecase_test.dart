import 'package:bedbug/infra/resources/content/content/content.config.dart';
import 'package:bedbug/infra/resources/content/content/content_origin.enum.dart';
import 'package:bedbug/infra/resources/content/content/text_content.entity.dart';
import 'package:bedbug/logic/usecases/content/save_content/save_content.params.dart';
import 'package:bedbug/logic/usecases/content/save_content/save_content.usecase.dart';
import 'package:bedbug/logic/usecases/feed/get_filtered_contents/get_filtered_contents.params.dart';
import 'package:bedbug/logic/usecases/feed/get_filtered_contents/get_filtered_contents.usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/drift_test_helper.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    container = createTestContainer();
  });

  tearDown(() async {
    container.dispose();
  });

  test('retourne uniquement les contenus dont le titre contient la query', () async {
    final saveUsecase = container.read(saveContentUsecaseProvider);
    final filterUsecase = container.read(getFilteredContentsUsecaseProvider);

    await saveUsecase(SaveContentParams(content: _buildTextContent('a', 'Punaises de lit')));
    await saveUsecase(SaveContentParams(content: _buildTextContent('b', 'Recette de cuisine')));

    final result = await filterUsecase(const GetFilteredContentsParams(query: 'punaise'));

    expect(result.isSuccess, isTrue);
    final contents = result.right!.items;
    expect(contents, hasLength(1));
    expect(contents.single.content.id, 'a');
  });

  test('la recherche est insensible à la casse', () async {
    final saveUsecase = container.read(saveContentUsecaseProvider);
    final filterUsecase = container.read(getFilteredContentsUsecaseProvider);

    await saveUsecase(SaveContentParams(content: _buildTextContent('a', 'Punaises de lit')));

    final result = await filterUsecase(const GetFilteredContentsParams(query: 'PUNAISES'));

    expect(result.right!.items, hasLength(1));
  });

  test('retourne une liste vide quand aucun titre ne correspond', () async {
    final saveUsecase = container.read(saveContentUsecaseProvider);
    final filterUsecase = container.read(getFilteredContentsUsecaseProvider);

    await saveUsecase(SaveContentParams(content: _buildTextContent('a', 'Punaises de lit')));

    final result = await filterUsecase(const GetFilteredContentsParams(query: 'inexistant'));

    expect(result.right!.items, isEmpty);
  });

  test('la casse est ignorée aussi pour les lettres accentuées, et les jokers SQL sont pris à la lettre', () async {
    final saveUsecase = container.read(saveContentUsecaseProvider);
    final filterUsecase = container.read(getFilteredContentsUsecaseProvider);
    await saveUsecase(SaveContentParams(content: _buildTextContent('ete', 'ÉTÉ à Paris')));
    await saveUsecase(SaveContentParams(content: _buildTextContent('autre', 'Autre chose')));

    final accented = await filterUsecase(const GetFilteredContentsParams(query: 'été'));
    final wildcard = await filterUsecase(const GetFilteredContentsParams(query: '%'));

    expect(accented.right!.items.map((detailed) => detailed.content.id), ['ete']);
    expect(wildcard.right!.items, isEmpty);
  });

  test('les résultats se lisent page par page, sans doublon ni trou', () async {
    final saveUsecase = container.read(saveContentUsecaseProvider);
    final filterUsecase = container.read(getFilteredContentsUsecaseProvider);
    for (var index = 0; index < contentPageSize + 5; index++) {
      await saveUsecase(SaveContentParams(content: _buildTextContent('c$index', 'Punaise $index')));
    }

    final first = (await filterUsecase(const GetFilteredContentsParams(query: 'punaise'))).right!;
    final second = (await filterUsecase(GetFilteredContentsParams(query: 'punaise', after: first.nextCursor))).right!;

    expect(first.items, hasLength(contentPageSize));
    expect(first.hasMore, isTrue);
    expect(second.items, hasLength(5));
    expect(second.hasMore, isFalse);
    final ids = [...first.items, ...second.items].map((detailed) => detailed.content.id).toSet();
    expect(ids, hasLength(contentPageSize + 5));
  });
}

TextContent _buildTextContent(String id, String title) {
  return TextContent(
    id: id,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    signatureId: 'local',
    flair: 'test',
    origin: ContentOrigin.owned,
    broadcastScore: 1,
    survivalScore: 1,
    displayScore: 1,
    bounce: 0,
    sizeInBytes: 10,
    title: title,
    body: 'Corps $id',
  );
}
