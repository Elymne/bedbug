import 'package:bedbug/application/exchange/passive_exchange_notifier.dart';
import 'package:bedbug/application/screens/home/home_screen.dart';
import 'package:bedbug/application/widgets/content_tile/content_widget.dart';
import 'package:bedbug/application/widgets/fields/content_search_input.dart';
import 'package:bedbug/application/widgets/ghost/app_ghost_icon.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/object_values/home_feed.dart';
import 'package:bedbug/features/content/domain/usecases/get_home_feed_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/mark_content_viewed_usecase.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

/// Fake [GetHomeFeedUsecase] retournant une liste fixe fournie au test.
class _FakeGetHomeFeedUsecase implements GetHomeFeedUsecase {
  _FakeGetHomeFeedUsecase(this._contents, {this.unviewedContentIds = const {}});
  final List<Content> _contents;

  /// Identifiants des contenus pas encore vus.
  final Set<String> unviewedContentIds;

  @override
  Future<Either<GetHomeFeedFailure, HomeFeed>> call(NoParams params) async {
    return Right(HomeFeed(contents: _contents, unviewedContentIds: unviewedContentIds));
  }
}

/// Fake [MarkContentViewedUsecase] retenant les contenus marqués comme vus.
class _FakeMarkContentViewedUsecase implements MarkContentViewedUsecase {
  /// Identifiants reçus, dans l'ordre.
  final List<String> viewedIds = [];

  @override
  Future<Either<MarkContentViewedFailure, void>> call(MarkContentViewedParams params) async {
    viewedIds.add(params.contentId);
    return const Right(null);
  }
}

TextContent _buildTextContent(String id) {
  return TextContent(
    id: id,
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
    title: 'Titre $id',
    body: 'Corps $id',
  );
}

/// Fake [GetHomeFeedUsecase] dont la liste change en cours de test, comme après la réception de contenus d'un pair.
class _ChangingGetHomeFeedUsecase implements GetHomeFeedUsecase {
  _ChangingGetHomeFeedUsecase(this.contents);

  /// Liste retournée au prochain appel.
  List<Content> contents;

  @override
  Future<Either<GetHomeFeedFailure, HomeFeed>> call(NoParams params) async {
    return Right(HomeFeed(contents: contents, unviewedContentIds: const {}));
  }
}

/// Fake [PassiveExchangeNotifier] dans un état d'activation fixe.
class _FakePassiveExchangeNotifier extends PassiveExchangeNotifier {
  _FakePassiveExchangeNotifier({required this.isActive});

  /// Indique si l'échange est actif.
  final bool isActive;

  @override
  Future<bool> build() async {
    return isActive;
  }
}

/// Monte un accueil vide avec l'échange actif ou coupé selon [isExchangeActive].
///
/// - [isExchangeActive] : `true` si l'échange tourne.
Future<void> _pumpEmptyHome(WidgetTester tester, {required bool isExchangeActive}) async {
  await pumpApp(
    tester,
    const HomeScreen(),
    overrides: [
      getHomeFeedUsecaseProvider.overrideWithValue(_FakeGetHomeFeedUsecase(const [])),
      passiveExchangeNotifierProvider.overrideWith(() => _FakePassiveExchangeNotifier(isActive: isExchangeActive)),
    ],
  );
  await tester.pump();
  await tester.pump();
}

/// Monte un accueil affichant les contenus [ids], dont [unviewedIds] ne sont pas encore vus.
///
/// - [ids] : identifiants des contenus du fil.
/// - [unviewedIds] : identifiants des contenus pas encore vus.
/// - [markUsecase] : reçoit les contenus marqués comme vus.
Future<void> _pumpHomeWithFeed(
  WidgetTester tester, {
  required List<String> ids,
  required Set<String> unviewedIds,
  required _FakeMarkContentViewedUsecase markUsecase,
}) async {
  await pumpApp(
    tester,
    const HomeScreen(),
    overrides: [
      getHomeFeedUsecaseProvider.overrideWithValue(
        _FakeGetHomeFeedUsecase(ids.map(_buildTextContent).toList(), unviewedContentIds: unviewedIds),
      ),
      markContentViewedUsecaseProvider.overrideWithValue(markUsecase),
    ],
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('seuls les contenus pas encore vus portent l\'icône animée', (tester) async {
    await _pumpHomeWithFeed(tester, ids: ['1', '2'], unviewedIds: {'1'}, markUsecase: _FakeMarkContentViewedUsecase());

    final unviewedTile = find.widgetWithText(ContentWidget, 'Titre 1');
    expect(find.descendant(of: unviewedTile, matching: find.byType(AppGhostIcon)), findsOneWidget);
    final viewedTile = find.widgetWithText(ContentWidget, 'Titre 2');
    expect(find.descendant(of: viewedTile, matching: find.byType(AppGhostIcon)), findsNothing);
  });

  testWidgets('un contenu resté une seconde à l\'écran est mémorisé une fois et garde son icône', (tester) async {
    final markUsecase = _FakeMarkContentViewedUsecase();
    await _pumpHomeWithFeed(tester, ids: ['1'], unviewedIds: {'1'}, markUsecase: markUsecase);

    await tester.pump(const Duration(milliseconds: 900));
    expect(markUsecase.viewedIds, isEmpty);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(seconds: 2));
    expect(markUsecase.viewedIds, ['1']);
    expect(find.byType(AppGhostIcon), findsAtLeastNWidgets(1));
  });

  testWidgets('un contenu sous le bord de l\'écran n\'est pas mémorisé', (tester) async {
    final markUsecase = _FakeMarkContentViewedUsecase();
    final ids = [for (var index = 0; index < 30; index++) '$index'];
    await _pumpHomeWithFeed(tester, ids: ids, unviewedIds: {'29'}, markUsecase: markUsecase);

    await tester.pump(const Duration(seconds: 2));

    expect(markUsecase.viewedIds, isEmpty);
  });

  testWidgets('un contenu qui ne fait que passer à l\'écran n\'est pas mémorisé', (tester) async {
    final markUsecase = _FakeMarkContentViewedUsecase();
    final ids = [for (var index = 0; index < 30; index++) '$index'];
    await _pumpHomeWithFeed(tester, ids: ids, unviewedIds: {'0'}, markUsecase: markUsecase);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(markUsecase.viewedIds, isEmpty);
  });

  testWidgets('un accueil vide conseille d\'activer l\'échange quand il est coupé', (tester) async {
    await _pumpEmptyHome(tester, isExchangeActive: false);

    expect(find.text('Aucun contenu disponible.'), findsOneWidget);
    expect(find.textContaining('Active l\'échange'), findsOneWidget);
  });

  testWidgets('un accueil vide ne conseille rien quand l\'échange tourne déjà', (tester) async {
    await _pumpEmptyHome(tester, isExchangeActive: true);

    expect(find.text('Aucun contenu disponible.'), findsOneWidget);
    expect(find.textContaining('Active l\'échange'), findsNothing);
  });

  testWidgets('tirer le fil vers le bas affiche les contenus reçus depuis', (tester) async {
    final usecase = _ChangingGetHomeFeedUsecase([_buildTextContent('1')]);
    await pumpApp(tester, const HomeScreen(), overrides: [getHomeFeedUsecaseProvider.overrideWithValue(usecase)]);
    await tester.pump();
    await tester.pump();
    expect(find.byType(ContentWidget), findsOneWidget);

    usecase.contents = [_buildTextContent('1'), _buildTextContent('2')];
    await tester.fling(find.byType(RefreshIndicator), const Offset(0, 300), 1000);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(RefreshProgressIndicator), findsNothing);

    expect(find.byType(ContentWidget), findsNWidgets(2));
  });

  testWidgets('un accueil vide se recharge aussi, pour faire apparaître les premiers contenus', (tester) async {
    final usecase = _ChangingGetHomeFeedUsecase([]);
    await pumpApp(tester, const HomeScreen(), overrides: [getHomeFeedUsecaseProvider.overrideWithValue(usecase)]);
    await tester.pump();
    await tester.pump();
    expect(find.byType(ContentWidget), findsNothing);

    usecase.contents = [_buildTextContent('1')];
    await tester.fling(find.byType(RefreshIndicator), const Offset(0, 300), 1000);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(RefreshProgressIndicator), findsNothing);

    expect(find.byType(ContentWidget), findsOneWidget);
  });

  testWidgets('affiche la barre de recherche et le message vide quand aucun contenu', (tester) async {
    await pumpApp(
      tester,
      const HomeScreen(),
      overrides: [getHomeFeedUsecaseProvider.overrideWithValue(_FakeGetHomeFeedUsecase(const []))],
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(ContentSearchInput), findsOneWidget);
    expect(find.byType(ContentWidget), findsNothing);
  });

  testWidgets('affiche un ContentWidget par contenu retourné', (tester) async {
    await pumpApp(
      tester,
      const HomeScreen(),
      overrides: [
        getHomeFeedUsecaseProvider.overrideWithValue(
          _FakeGetHomeFeedUsecase([_buildTextContent('1'), _buildTextContent('2')]),
        ),
      ],
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(ContentWidget), findsNWidgets(2));
  });
}
