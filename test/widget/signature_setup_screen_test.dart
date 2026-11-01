import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/signature_setup/signature_setup_screen.dart';
import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:bedbug/features/signature/domain/repositories/signature_repository.dart';
import 'package:bedbug/features/signature/domain/usecases/get_local_signature_usecase.dart';
import 'package:bedbug/features/signature/domain/usecases/save_local_signature_usecase.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Fake [GetLocalSignatureUsecase] simulant une signature jamais configurée.
class _FakeGetLocalSignatureUsecase implements GetLocalSignatureUsecase {
  @override
  Future<Either<GetLocalSignatureFailure, Signature?>> call(NoParams params) async => const Right(null);
}

/// Fake [SaveLocalSignatureUsecase] retenant les paramètres reçus.
class _FakeSaveLocalSignatureUsecase implements SaveLocalSignatureUsecase {
  /// Crée un [_FakeSaveLocalSignatureUsecase].
  ///
  /// - [failure] : échec à retourner, `null` pour réussir.
  _FakeSaveLocalSignatureUsecase({this.failure});

  /// Échec à retourner, `null` pour réussir.
  final SaveLocalSignatureFailure? failure;

  /// Paramètres du dernier enregistrement demandé.
  SaveLocalSignatureParams? lastParams;

  @override
  Future<Either<SaveLocalSignatureFailure, Signature>> call(SaveLocalSignatureParams params) async {
    lastParams = params;
    final failure = this.failure;
    if (failure != null) {
      return Left(failure);
    }
    return Right(
      Signature(id: localSignatureId, createdAt: DateTime(2026), updatedAt: DateTime(2026), pseudo: params.pseudo),
    );
  }
}

/// Monte la page de création avec un accueil factice derrière elle.
Future<void> _pumpSetup(WidgetTester tester, _FakeSaveLocalSignatureUsecase saveUsecase) async {
  // Écran haut : le formulaire tient en entier, le bouton reste à portée de tap.
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: signatureSetupPath,
    routes: [
      GoRoute(path: signatureSetupPath, builder: (context, state) => const SignatureSetupScreen()),
      GoRoute(
        path: homePath,
        builder: (context, state) => const Scaffold(body: Text('home')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        getLocalSignatureUsecaseProvider.overrideWithValue(_FakeGetLocalSignatureUsecase()),
        saveLocalSignatureUsecaseProvider.overrideWithValue(saveUsecase),
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
}

void main() {
  testWidgets("enregistrer la signature mène à l'accueil", (tester) async {
    final saveUsecase = _FakeSaveLocalSignatureUsecase();
    await _pumpSetup(tester, saveUsecase);

    await tester.enterText(find.byType(ReactiveTextField<String>).first, 'punaise');
    await tester.pump();
    await tester.tap(find.text("C'est parti"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(saveUsecase.lastParams?.pseudo, 'punaise');
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('sans pseudo, rien ne part et la page reste affichée', (tester) async {
    final saveUsecase = _FakeSaveLocalSignatureUsecase();
    await _pumpSetup(tester, saveUsecase);

    await tester.pump();
    await tester.tap(find.text("C'est parti"));
    await tester.pump();

    expect(saveUsecase.lastParams, isNull);
    expect(find.byType(SignatureSetupScreen), findsOneWidget);
  });

  testWidgets("un échec d'enregistrement laisse sur la page", (tester) async {
    final saveUsecase = _FakeSaveLocalSignatureUsecase(failure: SaveLocalSignatureFailure.storageError);
    await _pumpSetup(tester, saveUsecase);

    await tester.enterText(find.byType(ReactiveTextField<String>).first, 'punaise');
    await tester.pump();
    await tester.tap(find.text("C'est parti"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(saveUsecase.lastParams, isNotNull);
    expect(find.byType(SignatureSetupScreen), findsOneWidget);
    expect(find.text('home'), findsNothing);
  });
}
