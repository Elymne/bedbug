import 'dart:io';

import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_priority.dart';
import 'package:bedbug/features/content/domain/usecases/clear_contents_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/get_contents_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/save_content_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/seed_contents_usecase.dart';
import 'package:bedbug/shared/domain/params.dart';
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

  test('save puis get retourne le contenu sauvegardé, via le vrai repository Hive', () async {
    final saveUsecase = container.read(saveContentUsecaseProvider);
    final getUsecase = container.read(getContentsUsecaseProvider);

    final saveResult = await saveUsecase(SaveContentParams(content: _buildTextContent('a')));
    expect(saveResult.isSuccess, isTrue);

    final getResult = await getUsecase(const GetContentsParams());
    expect(getResult.isSuccess, isTrue);
    final contents = getResult.right!;
    expect(contents, hasLength(1));
    expect((contents.single as TextContent).title, 'Titre a');
  });

  test('clear supprime tous les contenus stockés', () async {
    final saveUsecase = container.read(saveContentUsecaseProvider);
    final getUsecase = container.read(getContentsUsecaseProvider);
    final clearUsecase = container.read(clearContentsUsecaseProvider);

    await saveUsecase(SaveContentParams(content: _buildTextContent('a')));
    await saveUsecase(SaveContentParams(content: _buildTextContent('b')));

    final clearResult = await clearUsecase(const NoParams());
    expect(clearResult.isSuccess, isTrue);

    final getResult = await getUsecase(const GetContentsParams());
    expect(getResult.right, isEmpty);
  });

  test('seed insère le nombre de contenus demandé', () async {
    final seedUsecase = container.read(seedContentsUsecaseProvider);
    final getUsecase = container.read(getContentsUsecaseProvider);

    final seedResult = await seedUsecase(const SeedContentsParams(count: 7));
    expect(seedResult.isSuccess, isTrue);

    final getResult = await getUsecase(const GetContentsParams());
    expect(getResult.right, hasLength(7));
  });
}

TextContent _buildTextContent(String id) {
  return TextContent(
    id: id,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    authorId: 'local',
    senderId: 'local',
    priority: ContentPriority.owned,
    bounce: 0,
    sizeInBytes: 10,
    title: 'Titre $id',
    body: 'Corps $id',
  );
}
