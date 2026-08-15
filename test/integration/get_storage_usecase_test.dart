import 'dart:io';

import 'package:bedbug/features/content/domain/entities/storage.dart';
import 'package:bedbug/features/content/domain/repositories/storage_repository.dart';
import 'package:bedbug/features/content/domain/usecases/get_storage_usecase.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_storage_repository.dart';
import 'package:bedbug/features/content/infrastructure/models/storage_hive_model.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:flutter/foundation.dart';
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

  test('crée et persiste une configuration par défaut quand aucune n\'existe, via le vrai repository Hive', () async {
    final usecase = container.read(getStorageUsecaseProvider);

    final result = await usecase(const NoParams());

    expect(result.isSuccess, isTrue);
    expect(result.right!.maxSizeInBytes, defaultMaxStorageSizeInBytes);
    expect(result.right!.currentSizeInBytes, 0);
  });

  test('retourne la configuration existante sans en recréer une, via le vrai repository Hive', () async {
    final usecase = container.read(getStorageUsecaseProvider);

    final first = await usecase(const NoParams());
    final second = await usecase(const NoParams());

    expect(second.right!.id, first.right!.id);
  });

  test('journalise un warning si plusieurs entrées sont trouvées dans le stockage sous-jacent', () async {
    final repository = container.read(storageRepositoryProvider);
    final box = container.read(hiveStorageBoxProvider);
    final usecase = container.read(getStorageUsecaseProvider);

    final now = DateTime.now();
    await repository.addOne(Storage(id: 'a', createdAt: now, updatedAt: now, maxSizeInBytes: 1000));
    // Simule une écriture buguée sous une mauvaise clé, en plus de l'entrée
    // singleton attendue.
    await box.put(
      'rogue-entry',
      StorageHiveModel.fromEntity(Storage(id: 'b', createdAt: now, updatedAt: now, maxSizeInBytes: 1000)),
    );

    final logs = <String>[];
    final previousDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) => logs.add(message ?? '');
    try {
      await usecase(const NoParams());
    } finally {
      debugPrint = previousDebugPrint;
    }

    expect(logs.any((log) => log.contains('WARNING')), isTrue);
  });
}
