import 'package:bedbug/application/screens/settings/settings_screen.dart';
import 'package:bedbug/application/screens/settings/widgets/settings_menu_tile.dart';
import 'package:bedbug/application/widgets/separators/app_list_separator.dart';
import 'package:bedbug/features/settings/domain/usecases/get_settings_usecase.dart';
import 'package:bedbug/features/settings/domain/value_objects/user_settings.dart';
import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:bedbug/features/signature/domain/usecases/get_local_signature_usecase.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

/// Fake [GetLocalSignatureUsecase] simulant un profil jamais configuré.
class _FakeGetLocalSignatureUsecase implements GetLocalSignatureUsecase {
  @override
  Future<Either<GetLocalSignatureFailure, Signature?>> call(NoParams params) async => const Right(null);
}

/// Fake [GetSettingsUsecase] retournant les réglages par défaut.
class _FakeGetSettingsUsecase implements GetSettingsUsecase {
  @override
  Future<Either<GetSettingsFailure, UserSettings>> call(NoParams params) async => const Right(UserSettings.empty());
}

void main() {
  testWidgets('affiche le menu des réglages, chacun avec sa description', (tester) async {
    await pumpApp(
      tester,
      const SettingsScreen(),
      overrides: [
        getLocalSignatureUsecaseProvider.overrideWithValue(_FakeGetLocalSignatureUsecase()),
        getSettingsUsecaseProvider.overrideWithValue(_FakeGetSettingsUsecase()),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Paramètres'), findsOneWidget);
    expect(find.text('Ma signature'), findsOneWidget);
    expect(find.text('Pas encore configurée'), findsOneWidget);
    expect(find.text('Publication'), findsOneWidget);
    expect(find.text('Comment tes contenus sont publiés'), findsOneWidget);
    expect(find.text('Mes posts'), findsOneWidget);
    expect(find.byType(SettingsMenuTile), findsNWidgets(7));
    expect(find.byType(AppListSeparator), findsNWidgets(6));
  });
}
