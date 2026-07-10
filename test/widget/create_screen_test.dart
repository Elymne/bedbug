import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/screens/create/create_screen.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/usecases/save_content_usecase.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Fake [SaveContentUsecase] capturant le contenu sauvegardé, sans toucher à
/// aucune infrastructure réelle.
class _FakeSaveContentUsecase implements SaveContentUsecase {
  Content? savedContent;

  @override
  Future<Either<SaveContentFailure, Content>> call(SaveContentParams params) async {
    savedContent = params.content;
    return Right(params.content);
  }
}

void main() {
  testWidgets('crée un contenu texte et revient à l\'écran précédent', (tester) async {
    final fakeSaveUsecase = _FakeSaveContentUsecase();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('home')),
        ),
        GoRoute(path: '/create', builder: (context, state) => const CreateScreen()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [saveContentUsecaseProvider.overrideWithValue(fakeSaveUsecase)],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          routerConfig: router,
        ),
      ),
    );

    router.push('/create');
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final l10n = lookupAppLocalizations(const Locale('fr'));
    await tester.enterText(find.widgetWithText(TextField, l10n.createTextTitleLabel), 'Mon titre');
    await tester.enterText(find.widgetWithText(TextField, l10n.createTextBodyLabel), 'Mon corps');
    await tester.tap(find.text(l10n.createSaveButton));
    await tester.pump();
    await tester.pump();

    expect(fakeSaveUsecase.savedContent, isNotNull);
    expect(find.text('home'), findsOneWidget);
  });
}
