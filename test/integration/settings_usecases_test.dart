import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/infra/resources/settings/user_settings/user_settings.config.dart';
import 'package:bedbug/logic/usecases/settings/get_settings/get_settings.usecase.dart';
import 'package:bedbug/logic/usecases/settings/save_settings/save_settings.params.dart';
import 'package:bedbug/logic/usecases/settings/save_settings/save_settings.usecase.dart';
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

  test('get crée et retourne des settings par défaut quand la base est vide', () async {
    final getUsecase = container.read(getSettingsUsecaseProvider);

    final result = await getUsecase(const NoParams());

    expect(result.isSuccess, isTrue);
    expect(result.right!.blockedUrls, isEmpty);
    expect(result.right!.blockedWords, isEmpty);
  });

  test('save puis get retourne les settings mis à jour, via le vrai repository drift', () async {
    final getUsecase = container.read(getSettingsUsecaseProvider);
    final saveUsecase = container.read(saveSettingsUsecaseProvider);

    await getUsecase(const NoParams());
    final saveResult = await saveUsecase(
      SaveSettingsParams(
        settings: defaultUserSettings.copyWith(blockedUrls: ['spam.com'], blockedWords: ['insulte']),
      ),
    );
    expect(saveResult.isSuccess, isTrue);

    final getResult = await getUsecase(const NoParams());
    expect(getResult.right!.blockedUrls, ['spam.com']);
    expect(getResult.right!.blockedWords, ['insulte']);
  });
}
