import 'dart:io';

import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/resources/content/storage/storage.config.dart';
import 'package:bedbug/resources/content/storage/storage.model.hive.dart';
import 'package:bedbug/resources/content/storage/storage.repository.hive.dart';
import 'package:bedbug/resources/content/storage/storage.value_object.dart';
import 'package:bedbug/usecases/storage/get_storage/get_storage.usecase.dart';
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

    expect(second.right, first.right);
    expect(await container.read(storageRepositoryProvider).countAll(), 1);
  });

  test('journalise un warning si plusieurs entrées sont trouvées dans le stockage sous-jacent', () async {
    final repository = container.read(storageRepositoryProvider);
    final box = container.read(hiveStorageBoxProvider);
    final usecase = container.read(getStorageUsecaseProvider);

    await repository.save(const Storage(maxSizeInBytes: 1000));
    // Simule une écriture buguée sous une mauvaise clé, en plus de l'entrée
    // singleton attendue.
    await box.put('rogue-entry', StorageHiveModel.fromEntity(const Storage(maxSizeInBytes: 1000)));

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
