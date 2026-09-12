import 'dart:io';

import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/providers/app_docs_dir_provider.dart';
import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/router/error_route_page.dart';
import 'package:bedbug/application/screens/content_detail/image_content_detail_screen.dart';
import 'package:bedbug/application/screens/content_detail/link_content_detail_screen.dart';
import 'package:bedbug/application/screens/content_detail/text_content_detail_screen.dart';
import 'package:bedbug/application/screens/create/create_screen.dart';
import 'package:bedbug/application/screens/home/home_screen.dart';
import 'package:bedbug/application/screens/search/search_screen.dart';
import 'package:bedbug/application/screens/settings/settings_screen.dart';
import 'package:bedbug/application/screens/splash/splash_screen.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/image_content.dart';
import 'package:bedbug/features/content/domain/entities/link_content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/usecases/clear_contents_usecase.dart';
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

/// Fake [ClearContentsUsecase] ne touchant à aucune infrastructure réelle.
class _FakeClearContentsUsecase implements ClearContentsUsecase {
  @override
  Future<Either<ClearContentsFailure, void>> call(NoParams params) async => const Right(null);
}

TextContent _buildTextContent() {
  return TextContent(
    id: 'text-1',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    authorId: 'local',
    senderId: 'local',
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
    authorId: 'local',
    senderId: 'local',
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

ImageContent _buildImageContent() {
  return ImageContent(
    id: 'image-1',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    authorId: 'local',
    senderId: 'local',
    origin: ContentOrigin.owned,
    broadcastScore: 1,
    survivalScore: 1,
    displayScore: 1,
    bounce: 0,
    sizeInBytes: 10,
    fileName: 'inexistant.jpg',
    imageWidth: 100,
    imageHeight: 100,
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
        seedContentsUsecaseProvider.overrideWithValue(_FakeSeedContentsUsecase()),
        clearContentsUsecaseProvider.overrideWithValue(_FakeClearContentsUsecase()),
        appDocsDirProvider.overrideWith((ref) async => Directory.systemTemp),
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

    for (final entry in <String, Type>{createPath: CreateScreen, settingsPath: SettingsScreen, searchPath: SearchScreen}
        .entries) {
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

    router.push(contentDetailPath, extra: _buildImageContent());
    await settleRoute(tester);
    expect(find.byType(ImageContentDetailScreen), findsOneWidget);
    router.pop();
    await settleRoute(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
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
