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

/// Construit un [TextContent] minimal pour les besoins du test.
///
/// `SaveContentUsecase` recalcule désormais le poids réel du contenu plutôt
/// que de faire confiance au `sizeInBytes` fourni au constructeur ; pour
/// garder un poids contrôlé et déterministe malgré ce recalcul, le corps est
/// composé de [bodyByteLength] caractères ASCII (1 octet chacun) et le titre
/// est laissé vide.
TextContent _buildContent({required String id, required int bodyByteLength}) {
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
    sizeInBytes: 0,
    title: '',
    body: 'a' * bodyByteLength,
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

    await saveUsecase(SaveContentParams(content: _buildContent(id: 'a', bodyByteLength: 100)));
    await saveUsecase(SaveContentParams(content: _buildContent(id: 'b', bodyByteLength: 250)));
    await saveUsecase(SaveContentParams(content: _buildContent(id: 'c', bodyByteLength: 0)));

    final result = await usecase(const NoParams());

    expect(result.isSuccess, isTrue);
    expect(result.right, 350);
  });

  test('corrige Storage.currentSizeInBytes si le compteur incrémental a dérivé, via le vrai repository Hive', () async {
    final saveUsecase = container.read(saveContentUsecaseProvider);
    final usecase = container.read(recalculateStorageUsageUsecaseProvider);
    final getStorageUsecase = container.read(getStorageUsecaseProvider);
    final storageRepository = container.read(storageRepositoryProvider);

    await saveUsecase(SaveContentParams(content: _buildContent(id: 'a', bodyByteLength: 100)));

    final drifted = (await storageRepository.getUnique(''))!;
    await storageRepository.updateOne(drifted.copyWithCurrentSizeInBytes(999999));

    final result = await usecase(const NoParams());
    expect(result.right, 100);

    final storageResult = await getStorageUsecase(const NoParams());
    expect(storageResult.right!.currentSizeInBytes, 100);
  });
}
