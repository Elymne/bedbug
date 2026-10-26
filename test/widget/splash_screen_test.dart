import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/screens/splash/splash_screen.dart';
import 'package:bedbug/application/screens/splash/widgets/app_title_text.dart';
import 'package:bedbug/features/content/domain/usecases/clear_contents_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/seed_contents_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/seed_reactions_usecase.dart';
import 'package:bedbug/features/signature/domain/usecases/seed_signatures_usecase.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Fake [ClearContentsUsecase] ne touchant à aucune infrastructure réelle.
class _FakeClearContentsUsecase implements ClearContentsUsecase {
  @override
  Future<Either<ClearContentsFailure, void>> call(NoParams params) async => const Right(null);
}

/// Fake [SeedContentsUsecase] ne touchant à aucune infrastructure réelle.
class _FakeSeedContentsUsecase implements SeedContentsUsecase {
  @override
  Future<Either<SeedContentsFailure, void>> call(SeedContentsParams params) async => const Right(null);
}

class _FakeSeedReactionsUsecase implements SeedReactionsUsecase {
  @override
  Future<Either<SeedReactionsFailure, void>> call(SeedReactionsParams params) async {
    return const Right(null);
  }
}

/// Fake [SeedSignaturesUsecase] ne touchant à aucune infrastructure réelle.
class _FakeSeedSignaturesUsecase implements SeedSignaturesUsecase {
  @override
  Future<Either<SeedSignaturesFailure, List<String>>> call(SeedSignaturesParams params) async => const Right([]);
}

void main() {
  testWidgets('affiche le logo et le titre puis navigue vers /home une fois le chargement terminé', (tester) async {
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('home')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clearContentsUsecaseProvider.overrideWithValue(_FakeClearContentsUsecase()),
          seedContentsUsecaseProvider.overrideWithValue(_FakeSeedContentsUsecase()),
          seedReactionsUsecaseProvider.overrideWithValue(_FakeSeedReactionsUsecase()),
          seedSignaturesUsecaseProvider.overrideWithValue(_FakeSeedSignaturesUsecase()),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          routerConfig: router,
        ),
      ),
    );

    expect(find.byType(AppTitleText), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
  });
}
