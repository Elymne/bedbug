import 'dart:io';

import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/usecases/delete_own_content_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/get_own_contents_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/get_storage_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/save_content_usecase.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/hive_test_helper.dart';
import '../helpers/seed_contents_usecase.dart';

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

  test('mes posts regroupent mes contenus, anonymes compris, du plus récent au plus ancien', () async {
    final saveUsecase = container.read(saveContentUsecaseProvider);
    await saveUsecase(SaveContentParams(content: _buildTextContent('ancien', ContentOrigin.owned, DateTime(2026))));
    await saveUsecase(
      SaveContentParams(
        content: _buildTextContent('anonyme', ContentOrigin.owned, DateTime(2026, 2), signatureId: 'anonymous'),
      ),
    );
    await saveUsecase(SaveContentParams(content: _buildTextContent('recu', ContentOrigin.public, DateTime(2026, 3))));

    final result = await container.read(getOwnContentsUsecaseProvider)(const NoParams());

    expect(result.right!.map((content) => content.id), ['anonyme', 'ancien']);
  });

  test('supprimer un de mes posts le retire et libère son poids dans le stockage', () async {
    final saveUsecase = container.read(saveContentUsecaseProvider);
    await saveUsecase(SaveContentParams(content: _buildTextContent('mien', ContentOrigin.owned, DateTime(2026))));
    final storageBefore = (await container.read(getStorageUsecaseProvider)(const NoParams())).right!;

    final result = await container.read(deleteOwnContentUsecaseProvider)(
      const DeleteOwnContentParams(contentId: 'mien'),
    );

    expect(result.isSuccess, isTrue);
    expect((await container.read(getOwnContentsUsecaseProvider)(const NoParams())).right, isEmpty);
    final storageAfter = (await container.read(getStorageUsecaseProvider)(const NoParams())).right!;
    expect(storageAfter.currentSizeInBytes, lessThan(storageBefore.currentSizeInBytes));
  });

  test("refuse de supprimer un contenu reçu d'un pair, ou introuvable", () async {
    await container.read(saveContentUsecaseProvider)(
      SaveContentParams(content: _buildTextContent('recu', ContentOrigin.public, DateTime(2026))),
    );
    final deleteUsecase = container.read(deleteOwnContentUsecaseProvider);

    final notOwned = await deleteUsecase(const DeleteOwnContentParams(contentId: 'recu'));
    final notFound = await deleteUsecase(const DeleteOwnContentParams(contentId: 'inexistant'));

    expect(notOwned.left, DeleteOwnContentFailure.notOwned);
    expect(notFound.left, DeleteOwnContentFailure.notFound);
  });

  test('les contenus factices ne passent jamais pour les miens', () async {
    await container.read(seedContentsUsecaseProvider)(const SeedContentsParams(count: 50));

    final result = await container.read(getOwnContentsUsecaseProvider)(const NoParams());

    expect(result.right, isEmpty);
  });
}

TextContent _buildTextContent(String id, ContentOrigin origin, DateTime createdAt, {String signatureId = 'local'}) {
  return TextContent(
    id: id,
    createdAt: createdAt,
    updatedAt: createdAt,
    signatureId: signatureId,
    flair: 'test',
    origin: origin,
    broadcastScore: 1,
    survivalScore: 1,
    displayScore: 1,
    bounce: 0,
    sizeInBytes: 10,
    title: 'Titre $id',
    body: 'Corps $id',
  );
}
