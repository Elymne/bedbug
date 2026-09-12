import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/home/home_screen.dart';
import 'package:bedbug/application/screens/search/search_screen.dart';
import 'package:bedbug/application/widgets/fields/content_search_input.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/usecases/get_home_feed_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/seed_contents_usecase.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Fake [GetHomeFeedUsecase] retournant toujours une liste vide.
class _FakeGetHomeFeedUsecase implements GetHomeFeedUsecase {
  @override
  Future<Either<GetHomeFeedFailure, List<Content>>> call(NoParams params) async => const Right([]);
}

/// Fake [SeedContentsUsecase] ne touchant à aucune infrastructure réelle.
class _FakeSeedContentsUsecase implements SeedContentsUsecase {
  @override
  Future<Either<SeedContentsFailure, void>> call(SeedContentsParams params) async => const Right(null);
}

void main() {
  Future<void> pumpHome(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: homePath,
      routes: [
        GoRoute(path: homePath, builder: (context, state) => const HomeScreen()),
        GoRoute(path: searchPath, builder: (context, state) => const SearchScreen()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          getHomeFeedUsecaseProvider.overrideWithValue(_FakeGetHomeFeedUsecase()),
          seedContentsUsecaseProvider.overrideWithValue(_FakeSeedContentsUsecase()),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('taper sur la barre de recherche de la home page pousse la vue de recherche', (tester) async {
    await pumpHome(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(SearchScreen), findsNothing);

    await tester.tap(find.byType(ContentSearchInput));
    await tester.pumpAndSettle();

    expect(find.byType(SearchScreen), findsOneWidget);
  });

  testWidgets('revenir en arrière depuis la vue de recherche restaure la home page', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byType(ContentSearchInput));
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);

    final searchScreenContext = tester.element(find.byType(SearchScreen));
    Navigator.of(searchScreenContext).pop();
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(SearchScreen), findsNothing);
  });
}
