import 'package:bedbug/application/screens/settings/settings_screen.dart';
import 'package:bedbug/features/settings/domain/usecases/get_settings_usecase.dart';
import 'package:bedbug/features/settings/domain/value_objects/user_settings.dart';
import 'package:bedbug/features/user/domain/entities/user.dart';
import 'package:bedbug/features/user/domain/usecases/get_local_user_usecase.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

/// Fake [GetLocalUserUsecase] simulant un profil jamais configuré.
class _FakeGetLocalUserUsecase implements GetLocalUserUsecase {
  @override
  Future<Either<GetLocalUserFailure, User?>> call(NoParams params) async => const Right(null);
}

/// Fake [GetSettingsUsecase] retournant les réglages par défaut.
class _FakeGetSettingsUsecase implements GetSettingsUsecase {
  @override
  Future<Either<GetSettingsFailure, UserSettings>> call(NoParams params) async => const Right(UserSettings.empty());
}

void main() {
  testWidgets('affiche la page de settings avec ses sections repliées', (tester) async {
    await pumpApp(
      tester,
      const SettingsScreen(),
      overrides: [
        getLocalUserUsecaseProvider.overrideWithValue(_FakeGetLocalUserUsecase()),
        getSettingsUsecaseProvider.overrideWithValue(_FakeGetSettingsUsecase()),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Paramètres'), findsOneWidget);
    expect(find.text('Mon profil'), findsOneWidget);
    expect(find.text('Pas encore configuré'), findsOneWidget);
    expect(find.text('Publication'), findsOneWidget);
    expect(find.text('Mes posts'), findsOneWidget);
  });
}
