import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/router/error_route_page.dart';
import 'package:bedbug/application/screens/content_detail/link_content_detail_screen.dart';
import 'package:bedbug/application/screens/content_detail/media_content_detail_screen.dart';
import 'package:bedbug/application/screens/content_detail/text_content_detail_screen.dart';
import 'package:bedbug/application/screens/create/create_screen.dart';
import 'package:bedbug/application/screens/exchange/exchange_screen.dart';
import 'package:bedbug/application/screens/home/home_screen.dart';
import 'package:bedbug/application/screens/search/search_screen.dart';
import 'package:bedbug/application/screens/select_options/select_options_screen.dart';
import 'package:bedbug/application/screens/settings/settings_screen.dart';
import 'package:bedbug/application/screens/settings/widgets/debug_section.dart';
import 'package:bedbug/application/screens/settings/widgets/language_section.dart';
import 'package:bedbug/application/screens/settings/widgets/own_contents_section.dart';
import 'package:bedbug/application/screens/settings/widgets/publishing_section.dart';
import 'package:bedbug/application/screens/settings/widgets/signature_section.dart';
import 'package:bedbug/application/screens/settings/widgets/storage_section.dart';
import 'package:bedbug/application/screens/settings/widgets/trust_section.dart';
import 'package:bedbug/application/screens/splash/splash_screen.dart';
import 'package:bedbug/application/widgets/fields/app_select_option.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/link_content.dart';
import 'package:bedbug/features/content/domain/entities/media_content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/object_values/content_media.dart';
import 'package:bedbug/features/content/domain/usecases/get_home_feed_usecase.dart';
import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:bedbug/features/signature/domain/usecases/get_local_signature_usecase.dart';
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

/// Fake [GetLocalSignatureUsecase] simulant un appareil déjà doté d'une signature.
class _FakeGetLocalSignatureUsecase implements GetLocalSignatureUsecase {
  @override
  Future<Either<GetLocalSignatureFailure, Signature?>> call(NoParams params) async {
    return Right(Signature(id: 'local', createdAt: DateTime(2026), updatedAt: DateTime(2026), pseudo: 'punaise'));
  }
}

TextContent _buildTextContent() {
  return TextContent(
    id: 'text-1',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    signatureId: 'local',
    flair: 'test',
    origin: ContentOrigin.owned,
    broadcastScore: 1,
    survivalScore: 1,
    displayScore: 1,
    bounce: 0,
    sizeInBytes: 10,
    title: 'Titre',
    body: 'Corps',
  );
}

LinkContent _buildLinkContent() {
  return LinkContent(
    id: 'link-1',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    signatureId: 'local',
    flair: 'test',
    origin: ContentOrigin.owned,
    broadcastScore: 1,
    survivalScore: 1,
    displayScore: 1,
    bounce: 0,
    sizeInBytes: 10,
    title: 'Titre',
    url: 'https://example.com',
  );
}

MediaContent _buildMediaContent() {
  return MediaContent(
    id: 'media-1',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    signatureId: 'local',
    flair: 'test',
    origin: ContentOrigin.owned,
    broadcastScore: 1,
    survivalScore: 1,
    displayScore: 1,
    bounce: 0,
    sizeInBytes: 10,
    // Domaine inconnu : le média reste voilé, rien n'est chargé pendant le test.
    media: const [ContentMedia(url: 'https://example.com/a.png', kind: MediaKind.image)],
    title: 'Titre',
  );
}

/// Laisse le temps à une transition de route de se terminer sans attendre
/// une stabilisation complète de l'arbre de widgets.
///
/// `pumpAndSettle` ne convient pas ici : certains écrans (`CreateScreen`,
/// via ses widgets `AppGhost*`) embarquent des animations en boucle
/// infinie (`repeat(reverse: true)`), qui ne se stabilisent jamais et font
/// timeout `pumpAndSettle` indéfiniment.
Future<void> settleRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  /// Monte l'application avec le vrai router (`routerProvider`), toutes
  /// dépendances métier remplacées par des fakes, et laisse passer le délai
  /// du splashscreen pour atterrir sur la home page.
  ///
  /// Retourne le [GoRouter] réel, pour le piloter directement à la main dans
  /// les tests (`push`/`pop`/`go`) plutôt que de dépendre du câblage bouton
  /// par bouton de chaque écran : le but ici est de bombarder le router de
  /// tous les enchaînements de routes possibles, pas de valider chaque UI.
  Future<GoRouter> pumpAppOnHome(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        getHomeFeedUsecaseProvider.overrideWithValue(_FakeGetHomeFeedUsecase()),
        getLocalSignatureUsecaseProvider.overrideWithValue(_FakeGetLocalSignatureUsecase()),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          routerConfig: router,
        ),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    return router;
  }

  testWidgets('push puis pop de chaque route simple revient proprement sur la home page', (tester) async {
    final router = await pumpAppOnHome(tester);

    for (final entry in <String, Type>{
      createPath: CreateScreen,
      exchangePath: ExchangeScreen,
      settingsPath: SettingsScreen,
      searchPath: SearchScreen,
    }.entries) {
      router.push(entry.key);
      await settleRoute(tester);
      expect(find.byType(entry.value), findsOneWidget, reason: 'échec en poussant ${entry.key}');
      expect(find.byType(ErrorRoutePage), findsNothing);

      router.pop();
      await settleRoute(tester);
      expect(find.byType(HomeScreen), findsOneWidget, reason: 'échec en revenant de ${entry.key}');
    }
  });

  testWidgets('la route de détail affiche le bon écran pour chaque sous-type de contenu', (tester) async {
    final router = await pumpAppOnHome(tester);

    router.push(contentDetailPath, extra: _buildTextContent());
    await settleRoute(tester);
    expect(find.byType(TextContentDetailScreen), findsOneWidget);
    router.pop();
    await settleRoute(tester);
    expect(find.byType(HomeScreen), findsOneWidget);

    router.push(contentDetailPath, extra: _buildLinkContent());
    await settleRoute(tester);
    expect(find.byType(LinkContentDetailScreen), findsOneWidget);
    router.pop();
    await settleRoute(tester);

    router.push(contentDetailPath, extra: _buildMediaContent());
    await settleRoute(tester);
    expect(find.byType(MediaContentDetailScreen), findsOneWidget);
    router.pop();
    await settleRoute(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('la page des options renvoie à l\'appelant la valeur choisie, avec son type', (tester) async {
    final router = await pumpAppOnHome(tester);

    final result = router.push<int>(
      selectOptionsPath,
      extra: const SelectOptionsParams(
        label: 'Choix',
        options: [
          AppSelectOption(value: 1, label: 'Un'),
          AppSelectOption(value: 2, label: 'Deux'),
        ],
        selectedValue: 1,
      ),
    );
    await settleRoute(tester);
    expect(find.byType(SelectOptionsScreen), findsOneWidget);

    await tester.tap(find.text('Deux'));
    await settleRoute(tester);

    expect(await result, 2);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('chaque ligne du menu des paramètres ouvre sa page, et le retour ramène au menu', (tester) async {
    final router = await pumpAppOnHome(tester);
    router.push(settingsPath);
    await settleRoute(tester);

    for (final entry in <String, Type>{
      'Ma signature': SignatureSection,
      'Langue': LanguageSection,
      'Publication': PublishingSection,
      'Domaines autorisés': TrustSection,
      'Stockage': StorageSection,
      'Mes posts': OwnContentsSection,
      'Debug': DebugSection,
    }.entries) {
      await tester.tap(find.text(entry.key));
      await settleRoute(tester);
      expect(find.byType(entry.value), findsOneWidget, reason: 'échec en ouvrant ${entry.key}');
      expect(find.text(entry.key), findsOneWidget, reason: 'titre absent sur ${entry.key}');
      expect(find.byType(SettingsScreen, skipOffstage: true), findsNothing);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await settleRoute(tester);
      expect(find.byType(SettingsScreen), findsOneWidget, reason: 'échec en revenant de ${entry.key}');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('le journal des échanges se referme sur la page debug', (tester) async {
    final router = await pumpAppOnHome(tester);
    router.push(settingsPath);
    await settleRoute(tester);
    router.push(settingsDebugPath);
    await settleRoute(tester);
    router.push(exchangeLogsPath);
    await settleRoute(tester);

    router.pop();
    await settleRoute(tester);

    expect(find.byType(DebugSection), findsOneWidget);
  });

  testWidgets('naviguer vers une route inconnue affiche la page d\'erreur, pas un crash', (tester) async {
    final router = await pumpAppOnHome(tester);

    router.push('/route-qui-n-existe-pas');
    await settleRoute(tester);

    expect(find.byType(ErrorRoutePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empiler plusieurs routes puis toutes les dépiler ne casse pas la stack', (tester) async {
    final router = await pumpAppOnHome(tester);

    router.push(createPath);
    await settleRoute(tester);
    router.push(searchPath);
    await settleRoute(tester);
    router.push(contentDetailPath, extra: _buildTextContent());
    await settleRoute(tester);

    expect(find.byType(TextContentDetailScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    router.pop();
    await settleRoute(tester);
    expect(find.byType(SearchScreen), findsOneWidget);

    router.pop();
    await settleRoute(tester);
    expect(find.byType(CreateScreen), findsOneWidget);

    router.pop();
    await settleRoute(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('go vers la home depuis une route imbriquée réinitialise la stack (pop impossible ensuite)', (
    tester,
  ) async {
    final router = await pumpAppOnHome(tester);

    router.push(createPath);
    await settleRoute(tester);
    router.push(searchPath);
    await settleRoute(tester);

    router.go(homePath);
    await settleRoute(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(router.canPop(), isFalse);
    expect(tester.takeException(), isNull);
  });
}
