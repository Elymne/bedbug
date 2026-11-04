import 'package:bedbug/application/screens/settings/settings.screen.dart';
import 'package:bedbug/application/screens/settings/settings_menu_tile/settings_menu_tile.widget.dart';
import 'package:bedbug/application/widgets/separators/app_list_separator.widget.dart';
import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/resources/settings/user_settings/user_settings.config.dart';
import 'package:bedbug/resources/settings/user_settings/user_settings.value_object.dart';
import 'package:bedbug/resources/signature/signature/signature.entity.dart';
import 'package:bedbug/usecases/settings/get_settings/get_settings.failure.dart';
import 'package:bedbug/usecases/settings/get_settings/get_settings.usecase.dart';
import 'package:bedbug/usecases/signature/get_local_signature/get_local_signature.failure.dart';
import 'package:bedbug/usecases/signature/get_local_signature/get_local_signature.usecase.dart';
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
  Future<Either<GetSettingsFailure, UserSettings>> call(NoParams params) async => const Right(defaultUserSettings);
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
