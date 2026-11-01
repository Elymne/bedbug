import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/screens/splash/splash_screen.dart';
import 'package:bedbug/application/screens/splash/widgets/app_title_text.dart';
import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:bedbug/features/signature/domain/usecases/get_local_signature_usecase.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Fake [GetLocalSignatureUsecase] retournant le résultat fourni.
class _FakeGetLocalSignatureUsecase implements GetLocalSignatureUsecase {
  /// Crée un [_FakeGetLocalSignatureUsecase].
  ///
  /// - [result] : résultat de la lecture de la signature locale.
  _FakeGetLocalSignatureUsecase(this.result);

  /// Résultat de la lecture de la signature locale.
  final Either<GetLocalSignatureFailure, Signature?> result;

  @override
  Future<Either<GetLocalSignatureFailure, Signature?>> call(NoParams params) async => result;
}

/// Monte le splashscreen avec des destinations factices et laisse passer son délai.
Future<void> pumpSplash(WidgetTester tester, Either<GetLocalSignatureFailure, Signature?> signatureResult) async {
  final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/home',
        builder: (context, state) => const Scaffold(body: Text('home')),
      ),
      GoRoute(
        path: '/signature-setup',
        builder: (context, state) => const Scaffold(body: Text('setup')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [getLocalSignatureUsecaseProvider.overrideWithValue(_FakeGetLocalSignatureUsecase(signatureResult))],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        routerConfig: router,
      ),
    ),
  );

  expect(find.byType(AppTitleText), findsOneWidget);

  await tester.pump();
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('avec une signature, affiche le logo et le titre puis navigue vers /home', (tester) async {
    final signature = Signature(id: 'local', createdAt: DateTime(2026), updatedAt: DateTime(2026), pseudo: 'punaise');

    await pumpSplash(tester, Right(signature));

    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('sans signature, navigue vers la page de création', (tester) async {
    await pumpSplash(tester, const Right(null));

    expect(find.text('setup'), findsOneWidget);
  });

  testWidgets('une lecture en échec ne renvoie pas vers la création', (tester) async {
    await pumpSplash(tester, const Left(GetLocalSignatureFailure.storageError));

    expect(find.text('home'), findsOneWidget);
  });
}
