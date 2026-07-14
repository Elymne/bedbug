import 'dart:io';

import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/usecases/get_storage_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/recalculate_storage_usage_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/save_content_usecase.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_storage_repository.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/hive_test_helper.dart';

/// Construit un [TextContent] minimal pour les besoins du test, avec un
/// [sizeInBytes] contrôlé pour vérifier le calcul du poids total.
TextContent _buildContent({required String id, required int sizeInBytes}) {
  final now = DateTime.now();
  return TextContent(
    id: id,
    createdAt: now,
    updatedAt: now,
    authorId: 'author',
    senderId: 'sender',
    origin: ContentOrigin.owned,
    broadcastScore: 1,
    survivalScore: 1,
    displayScore: 1,
    bounce: 0,
    sizeInBytes: sizeInBytes,
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

  test('retourne 0 quand aucun contenu n\'est stocké, via le vrai repository Hive', () async {
    final usecase = container.read(recalculateStorageUsageUsecaseProvider);

    final result = await usecase(const NoParams());

    expect(result.isSuccess, isTrue);
    expect(result.right, 0);
  });

  test('additionne le sizeInBytes de tous les contenus stockés, via le vrai repository Hive', () async {
    final saveUsecase = container.read(saveContentUsecaseProvider);
    final usecase = container.read(recalculateStorageUsageUsecaseProvider);

    await saveUsecase(SaveContentParams(content: _buildContent(id: 'a', sizeInBytes: 100)));
    await saveUsecase(SaveContentParams(content: _buildContent(id: 'b', sizeInBytes: 250)));
    await saveUsecase(SaveContentParams(content: _buildContent(id: 'c', sizeInBytes: 0)));

    final result = await usecase(const NoParams());

    expect(result.isSuccess, isTrue);
    expect(result.right, 350);
  });

  test('corrige Storage.currentSizeInBytes si le compteur incrémental a dérivé, via le vrai repository Hive', () async {
    final saveUsecase = container.read(saveContentUsecaseProvider);
    final usecase = container.read(recalculateStorageUsageUsecaseProvider);
    final getStorageUsecase = container.read(getStorageUsecaseProvider);
    final storageRepository = container.read(storageRepositoryProvider);

    await saveUsecase(SaveContentParams(content: _buildContent(id: 'a', sizeInBytes: 100)));

    final drifted = (await storageRepository.getUnique(''))!;
    await storageRepository.updateOne(drifted.copyWithCurrentSizeInBytes(999999));

    final result = await usecase(const NoParams());
    expect(result.right, 100);

    final storageResult = await getStorageUsecase(const NoParams());
    expect(storageResult.right!.currentSizeInBytes, 100);
  });
}
