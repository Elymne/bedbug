import 'dart:io';

import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/usecases/get_filtered_contents_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/save_content_usecase.dart';
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

  test('retourne uniquement les contenus dont le titre contient la query, via le vrai repository Hive', () async {
    final saveUsecase = container.read(saveContentUsecaseProvider);
    final filterUsecase = container.read(getFilteredContentsUsecaseProvider);

    await saveUsecase(SaveContentParams(content: _buildTextContent('a', 'Punaises de lit')));
    await saveUsecase(SaveContentParams(content: _buildTextContent('b', 'Recette de cuisine')));

    final result = await filterUsecase(const GetFilteredContentsParams(query: 'punaise'));

    expect(result.isSuccess, isTrue);
    final contents = result.right!;
    expect(contents, hasLength(1));
    expect((contents.single as TextContent).id, 'a');
  });

  test('la recherche est insensible à la casse', () async {
    final saveUsecase = container.read(saveContentUsecaseProvider);
    final filterUsecase = container.read(getFilteredContentsUsecaseProvider);

    await saveUsecase(SaveContentParams(content: _buildTextContent('a', 'Punaises de lit')));

    final result = await filterUsecase(const GetFilteredContentsParams(query: 'PUNAISES'));

    expect(result.right, hasLength(1));
  });

  test('retourne une liste vide quand aucun titre ne correspond', () async {
    final saveUsecase = container.read(saveContentUsecaseProvider);
    final filterUsecase = container.read(getFilteredContentsUsecaseProvider);

    await saveUsecase(SaveContentParams(content: _buildTextContent('a', 'Punaises de lit')));

    final result = await filterUsecase(const GetFilteredContentsParams(query: 'inexistant'));

    expect(result.right, isEmpty);
  });
}

TextContent _buildTextContent(String id, String title) {
  return TextContent(
    id: id,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    authorId: 'local',
    senderId: 'local',
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
