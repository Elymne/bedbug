import 'dart:io';

import 'package:bedbug/features/settings/domain/usecases/get_settings_usecase.dart';
import 'package:bedbug/features/settings/domain/usecases/save_settings_usecase.dart';
import 'package:bedbug/features/settings/domain/value_objects/user_settings.dart';
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

  test('get crée et retourne des settings par défaut quand la box est vide', () async {
    final getUsecase = container.read(getSettingsUsecaseProvider);

    final result = await getUsecase(const NoParams());

    expect(result.isSuccess, isTrue);
    expect(result.right!.blockedUrls, isEmpty);
    expect(result.right!.blockedWords, isEmpty);
  });

  test('save puis get retourne les settings mis à jour, via le vrai repository Hive', () async {
    final getUsecase = container.read(getSettingsUsecaseProvider);
    final saveUsecase = container.read(saveSettingsUsecaseProvider);

    await getUsecase(const NoParams());
    final saveResult = await saveUsecase(
      const SaveSettingsParams(
        settings: UserSettings(blockedUrls: ['spam.com'], blockedWords: ['insulte']),
      ),
    );
    expect(saveResult.isSuccess, isTrue);

    final getResult = await getUsecase(const NoParams());
    expect(getResult.right!.blockedUrls, ['spam.com']);
    expect(getResult.right!.blockedWords, ['insulte']);
  });
}
