import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/home/home_screen.dart';
import 'package:bedbug/application/screens/settings/settings_screen.dart';
import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/resources/settings/user_settings/user_settings.config.dart';
import 'package:bedbug/resources/settings/user_settings/user_settings.value_object.dart';
import 'package:bedbug/resources/signature/signature/signature.entity.dart';
import 'package:bedbug/usecases/feed/get_home_feed/get_home_feed.failure.dart';
import 'package:bedbug/usecases/feed/get_home_feed/get_home_feed.result.dart';
import 'package:bedbug/usecases/feed/get_home_feed/get_home_feed.usecase.dart';
import 'package:bedbug/usecases/settings/get_settings/get_settings.failure.dart';
import 'package:bedbug/usecases/settings/get_settings/get_settings.usecase.dart';
import 'package:bedbug/usecases/signature/get_local_signature/get_local_signature.failure.dart';
import 'package:bedbug/usecases/signature/get_local_signature/get_local_signature.usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/find_app_icon.dart';

/// Fake [GetHomeFeedUsecase] retournant toujours une liste vide.
class _FakeGetHomeFeedUsecase implements GetHomeFeedUsecase {
  @override
  Future<Either<GetHomeFeedFailure, HomeFeed>> call(NoParams params) async {
    return const Right(HomeFeed(contents: [], unviewedContentIds: {}));
  }
}

/// Fake [GetLocalSignatureUsecase] simulant une signature jamais configurée.
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
  // Non-régression : les paramètres étaient ouverts avec `go`, qui remplaçait
  // la pile ; le retour système quittait alors l'app au lieu de revenir.
  testWidgets("l'onglet paramètres s'empile au-dessus de la home, et le retour y ramène", (tester) async {
    final router = GoRouter(
      initialLocation: homePath,
      routes: [
        GoRoute(path: homePath, builder: (context, state) => const HomeScreen()),
        GoRoute(path: settingsPath, builder: (context, state) => const SettingsScreen()),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          getHomeFeedUsecaseProvider.overrideWithValue(_FakeGetHomeFeedUsecase()),
          getLocalSignatureUsecaseProvider.overrideWithValue(_FakeGetLocalSignatureUsecase()),
          getSettingsUsecaseProvider.overrideWithValue(_FakeGetSettingsUsecase()),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(findAppIcon(AppIcons.settings));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(router.canPop(), isTrue);

    await tester.tap(findAppIcon(AppIcons.arrowBack));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
