import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/infra/resources/content/storage/storage.config.dart';
import 'package:bedbug/infra/resources/content/storage/storage.repository.drift.dart';
import 'package:bedbug/infra/resources/content/storage/storage.value_object.dart';
import 'package:bedbug/infra/resources/drift.database.dart';
import 'package:bedbug/logic/usecases/storage/get_storage/get_storage.usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/drift_test_helper.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = createTestContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('crée et persiste une configuration par défaut quand aucune n\'existe', () async {
    final usecase = container.read(getStorageUsecaseProvider);

    final result = await usecase(const NoParams());

    expect(result.isSuccess, isTrue);
    expect(result.right, defaultStorage);
    expect(await container.read(storageRepositoryProvider).get(), defaultStorage);
  });

  test('retourne la configuration existante sans en recréer une', () async {
    final usecase = container.read(getStorageUsecaseProvider);
    await container.read(storageRepositoryProvider).save(const Storage(maxSizeInBytes: 42 * bytesPerMegabyte));

    final first = await usecase(const NoParams());
    final second = await usecase(const NoParams());

    expect(first.right?.maxSizeInBytes, 42 * bytesPerMegabyte);
    expect(second.right, first.right);
    final database = container.read(appDatabaseProvider);
    expect(await database.select(database.storageSettings).get(), hasLength(1));
  });

  test('le poids utilisé est celui de la base, mesuré et non stocké', () async {
    final repository = container.read(storageRepositoryProvider);

    final usedBytes = await repository.getUsedSizeInBytes();

    expect(usedBytes, greaterThan(0));
    expect(usedBytes, await container.read(appDatabaseProvider).usedSizeInBytes());
  });
}
