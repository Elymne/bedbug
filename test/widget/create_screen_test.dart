import 'dart:async';

import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/create/create_screen.dart';
import 'package:bedbug/application/widgets/tags/app_tag.dart';
import 'package:bedbug/application/widgets/texts/app_loading_text.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/tag.dart';
import 'package:bedbug/features/content/domain/usecases/save_content_usecase.dart';
import 'package:bedbug/features/settings/domain/usecases/get_settings_usecase.dart';
import 'package:bedbug/features/settings/domain/value_objects/user_settings.dart';
import 'package:bedbug/features/signature/domain/entities/anonymous_signature.dart';
import 'package:bedbug/features/signature/domain/repositories/signature_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
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

/// Fake [SaveContentUsecase] qui ne termine la sauvegarde qu'une fois [completer] complété,
/// pour observer l'écran pendant une publication lente.
class _SlowSaveContentUsecase extends _FakeSaveContentUsecase {
  /// Complété par le test pour laisser la sauvegarde se terminer.
  final Completer<void> completer = Completer<void>();

  @override
  Future<Either<SaveContentFailure, Content>> call(SaveContentParams params) async {
    await completer.future;
    return super.call(params);
  }
}

/// Fake [GetSettingsUsecase] retournant des réglages fixes, sans toucher à Hive.
class _FakeGetSettingsUsecase implements GetSettingsUsecase {
  /// Crée un [_FakeGetSettingsUsecase].
  ///
  /// - [isAnonymousByDefault] : valeur du réglage de publication anonyme par défaut.
  _FakeGetSettingsUsecase({this.isAnonymousByDefault = false});

  /// Valeur du réglage de publication anonyme par défaut.
  final bool isAnonymousByDefault;

  @override
  Future<Either<GetSettingsFailure, UserSettings>> call(NoParams params) async {
    return Right(
      UserSettings(blockedUrls: const [], blockedWords: const [], isAnonymousByDefault: isAnonymousByDefault),
    );
  }
}

/// Monte l'écran de création derrière une page d'accueil factice, prêt à être rempli.
Future<void> _pumpCreateScreen(
  WidgetTester tester, {
  required _FakeSaveContentUsecase saveUsecase,
  bool isAnonymousByDefault = false,
}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Text('home')),
      ),
      GoRoute(path: '/create', builder: (context, state) => const CreateScreen()),
      GoRoute(
        path: contentDetailPath,
        builder: (context, state) => Scaffold(body: Text('detail ${(state.extra! as TextContent).title}')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        saveContentUsecaseProvider.overrideWithValue(saveUsecase),
        getSettingsUsecaseProvider.overrideWithValue(
          _FakeGetSettingsUsecase(isAnonymousByDefault: isAnonymousByDefault),
        ),
      ],
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
}

/// Remplit un contenu texte valide et appuie sur « Enregistrer ».
Future<void> _fillAndSaveTextContent(WidgetTester tester) async {
  final l10n = lookupAppLocalizations(const Locale('fr'));
  await tester.enterText(find.widgetWithText(TextField, l10n.createFlairLabel), 'france');
  await tester.enterText(find.widgetWithText(TextField, l10n.createTextTitleLabel), 'Mon titre');
  await tester.enterText(find.widgetWithText(TextField, l10n.createTextBodyLabel), 'Mon corps');
  await tester.tap(find.text(l10n.createSaveButton));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets("un contenu est signé par l'utilisateur du téléphone quand la case anonyme est décochée", (tester) async {
    final fakeSaveUsecase = _FakeSaveContentUsecase();
    await _pumpCreateScreen(tester, saveUsecase: fakeSaveUsecase);

    await _fillAndSaveTextContent(tester);

    expect(fakeSaveUsecase.savedContent!.authorId, localSignatureId);
  });

  testWidgets('la case anonyme part cochée selon le réglage, et le contenu est alors signé anonyme', (tester) async {
    final fakeSaveUsecase = _FakeSaveContentUsecase();
    await _pumpCreateScreen(tester, saveUsecase: fakeSaveUsecase, isAnonymousByDefault: true);

    final l10n = lookupAppLocalizations(const Locale('fr'));
    final checkbox = tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, l10n.createAnonymousLabel));
    expect(checkbox.value, isTrue);

    await _fillAndSaveTextContent(tester);

    expect(fakeSaveUsecase.savedContent!.authorId, anonymousSignatureId);
  });

  testWidgets('crée un contenu texte, ouvre son détail, et un retour ramène à l\'accueil', (tester) async {
    final fakeSaveUsecase = _FakeSaveContentUsecase();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('home')),
        ),
        GoRoute(path: '/create', builder: (context, state) => const CreateScreen()),
        GoRoute(
          path: contentDetailPath,
          builder: (context, state) => Scaffold(body: Text('detail ${(state.extra! as TextContent).title}')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          saveContentUsecaseProvider.overrideWithValue(fakeSaveUsecase),
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

    router.push('/create');
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final l10n = lookupAppLocalizations(const Locale('fr'));
    await tester.enterText(find.widgetWithText(TextField, l10n.createFlairLabel), '/France ');
    await tester.enterText(find.widgetWithText(TextField, l10n.createTextTitleLabel), 'Mon titre');
    await tester.enterText(find.widgetWithText(TextField, l10n.createTextBodyLabel), 'Mon corps');
    await tester.tap(find.text(l10n.createSaveButton));
    await tester.pump();
    await tester.pump();

    expect(fakeSaveUsecase.savedContent, isNotNull);
    expect(fakeSaveUsecase.savedContent!.flair, 'france');
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('detail Mon titre'), findsOneWidget);

    router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('refuse la création tant que le flair est vide ou réduit à /', (tester) async {
    final fakeSaveUsecase = _FakeSaveContentUsecase();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('home')),
        ),
        GoRoute(path: '/create', builder: (context, state) => const CreateScreen()),
        GoRoute(
          path: contentDetailPath,
          builder: (context, state) => Scaffold(body: Text('detail ${(state.extra! as TextContent).title}')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          saveContentUsecaseProvider.overrideWithValue(fakeSaveUsecase),
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

    router.push('/create');
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final l10n = lookupAppLocalizations(const Locale('fr'));
    await tester.enterText(find.widgetWithText(TextField, l10n.createFlairLabel), '/');
    await tester.enterText(find.widgetWithText(TextField, l10n.createTextTitleLabel), 'Mon titre');
    await tester.enterText(find.widgetWithText(TextField, l10n.createTextBodyLabel), 'Mon corps');
    await tester.tap(find.text(l10n.createSaveButton));
    await tester.pump();
    await tester.pump();

    expect(fakeSaveUsecase.savedContent, isNull);
    expect(find.text(l10n.createFlairRequiredError), findsOneWidget);
  });

  testWidgets('associe les tags sélectionnés au contenu créé', (tester) async {
    final fakeSaveUsecase = _FakeSaveContentUsecase();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('home')),
        ),
        GoRoute(path: '/create', builder: (context, state) => const CreateScreen()),
        GoRoute(
          path: contentDetailPath,
          builder: (context, state) => Scaffold(body: Text('detail ${(state.extra! as TextContent).title}')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          saveContentUsecaseProvider.overrideWithValue(fakeSaveUsecase),
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

    router.push('/create');
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final l10n = lookupAppLocalizations(const Locale('fr'));
    await tester.enterText(find.widgetWithText(TextField, l10n.createTextTitleLabel), 'Mon titre');
    await tester.enterText(find.widgetWithText(TextField, l10n.createTextBodyLabel), 'Mon corps');
    await tester.enterText(find.widgetWithText(TextField, l10n.createFlairLabel), 'test');
    await tester.tap(find.widgetWithText(AppTag, Tag.alert.text));
    await tester.tap(find.widgetWithText(AppTag, Tag.question.text));
    await tester.tap(find.text(l10n.createSaveButton));
    await tester.pump();
    await tester.pump();

    expect(fakeSaveUsecase.savedContent, isNotNull);
    expect(fakeSaveUsecase.savedContent!.tags, containsAll(<Tag>[Tag.alert, Tag.question]));
    expect(fakeSaveUsecase.savedContent!.tags, hasLength(2));
  });

  testWidgets('affiche une page de chargement pendant toute la publication, puis ouvre le contenu créé', (
    tester,
  ) async {
    final slowSaveUsecase = _SlowSaveContentUsecase();
    await _pumpCreateScreen(tester, saveUsecase: slowSaveUsecase);

    await _fillAndSaveTextContent(tester);

    expect(find.byType(AppLoadingText), findsOneWidget);

    slowSaveUsecase.completer.complete();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(AppLoadingText), findsNothing);
    expect(find.text('detail Mon titre'), findsOneWidget);
  });
}
