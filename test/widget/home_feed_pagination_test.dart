import 'package:bedbug/application/screens/content_detail/reaction_composer_sheet/reaction_composer_sheet.notifier.dart';
import 'package:bedbug/application/screens/home/home.screen.dart';
import 'package:bedbug/application/screens/home/home_feed/home_feed.notifier.dart';
import 'package:bedbug/application/widgets/content_tile/content.widget.dart';
import 'package:bedbug/core/domain/cursor_page.dart';
import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/infra/resources/content/content/content.entity.detailed.dart';
import 'package:bedbug/infra/resources/content/content/content_origin.enum.dart';
import 'package:bedbug/infra/resources/content/content/text_content.entity.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.entity.dart';
import 'package:bedbug/infra/resources/signature/signature/signature.entity.dart';
import 'package:bedbug/infra/resources/signature/signature/text_font.enum.dart';
import 'package:bedbug/logic/usecases/feed/get_home_feed/get_home_feed.failure.dart';
import 'package:bedbug/logic/usecases/feed/get_home_feed/get_home_feed.params.dart';
import 'package:bedbug/logic/usecases/feed/get_home_feed/get_home_feed.usecase.dart';
import 'package:bedbug/logic/usecases/reaction/count_content_reactions/count_content_reactions.failure.dart';
import 'package:bedbug/logic/usecases/reaction/count_content_reactions/count_content_reactions.params.dart';
import 'package:bedbug/logic/usecases/reaction/count_content_reactions/count_content_reactions.usecase.dart';
import 'package:bedbug/logic/usecases/reaction/save_reaction/save_reaction.failure.dart';
import 'package:bedbug/logic/usecases/reaction/save_reaction/save_reaction.params.dart';
import 'package:bedbug/logic/usecases/reaction/save_reaction/save_reaction.usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

/// Fake [GetHomeFeedUsecase] servant des pages fixes, indexées par le curseur qui les demande.
///
/// Le curseur d'une page est l'index, dans [pages], de la page suivante : `null` pour la première page, puis `'1'`,
/// `'2'`… La dernière page n'a pas de curseur suivant.
class _PagedGetHomeFeedUsecase implements GetHomeFeedUsecase {
  _PagedGetHomeFeedUsecase(this.pages);

  /// Pages du fil, dans l'ordre.
  final List<List<ContentDetailed>> pages;

  /// Curseurs pour lesquels le prochain appel échoue, une seule fois chacun.
  final Set<String> failingCursors = {};

  /// Paramètres reçus, dans l'ordre des appels.
  final List<GetHomeFeedParams> calls = [];

  @override
  Future<Either<GetHomeFeedFailure, CursorPage<ContentDetailed>>> call(GetHomeFeedParams params) async {
    calls.add(params);
    final after = params.after;
    if (after != null && failingCursors.remove(after)) {
      return const Left(GetHomeFeedFailure.storageError);
    }
    final index = after == null ? 0 : int.parse(after);
    final isLast = index == pages.length - 1;
    return Right(CursorPage(items: pages[index], nextCursor: isLast ? null : '${index + 1}'));
  }
}

/// Fake [SaveReactionUsecase] acceptant toute réaction.
class _FakeSaveReactionUsecase implements SaveReactionUsecase {
  @override
  Future<Either<SaveReactionFailure, Reaction>> call(SaveReactionParams params) async {
    return Right(params.reaction);
  }
}

/// Fake [CountContentReactionsUsecase] retournant un nombre fixe.
class _FakeCountContentReactionsUsecase implements CountContentReactionsUsecase {
  _FakeCountContentReactionsUsecase(this.reactionCount);

  /// Nombre de réactions retourné.
  final int reactionCount;

  @override
  Future<Either<CountContentReactionsFailure, int>> call(CountContentReactionsParams params) async {
    return Right(reactionCount);
  }
}

/// Construit un contenu du fil, déjà vu, d'identifiant [id].
///
/// - [id] : identifiant du contenu.
/// - [signature] : signature de l'auteur, `null` pour un auteur inconnu.
/// - [reactionCount] : nombre de réactions du contenu.
ContentDetailed _buildDetailed(String id, {Signature? signature, int reactionCount = 0}) {
  return ContentDetailed(
    content: TextContent(
      id: id,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      signatureId: 'author',
      flair: 'test',
      origin: ContentOrigin.public,
      broadcastScore: 1,
      survivalScore: 1,
      displayScore: 1,
      bounce: 0,
      sizeInBytes: 10,
      title: 'Titre $id',
      body: 'Corps $id',
    ),
    signature: signature,
    reactionCount: reactionCount,
    isViewed: true,
  );
}

/// Construit une page de [count] contenus, d'identifiants `prefix0`, `prefix1`…
///
/// - [prefix] : préfixe des identifiants.
/// - [count] : nombre de contenus de la page.
List<ContentDetailed> _buildPage(String prefix, int count) {
  return [for (var index = 0; index < count; index++) _buildDetailed('$prefix$index')];
}

/// Monte l'accueil sur [usecase] et attend l'affichage de la première page.
///
/// - [usecase] : fake du fil à brancher.
/// - [overrides] : surcharges supplémentaires.
Future<void> _pumpHome(
  WidgetTester tester,
  _PagedGetHomeFeedUsecase usecase, {
  List<Override> overrides = const [],
}) async {
  await pumpApp(
    tester,
    const HomeScreen(),
    overrides: [getHomeFeedUsecaseProvider.overrideWithValue(usecase), ...overrides],
  );
  await tester.pump();
  await tester.pump();
}

/// Retourne le conteneur de providers de l'accueil monté.
ProviderContainer _containerOf(WidgetTester tester) {
  return ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));
}

/// Fait défiler le fil jusqu'en bas, plusieurs fois, en laissant chaque page suivante arriver.
Future<void> _scrollToEnd(WidgetTester tester) async {
  for (var step = 0; step < 15; step++) {
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pump();
    await tester.pump();
  }
}

void main() {
  testWidgets('charge la page suivante à l\'approche de la fin et s\'arrête une fois le fil épuisé', (tester) async {
    final usecase = _PagedGetHomeFeedUsecase([_buildPage('a', 30), _buildPage('b', 30), _buildPage('c', 30)]);
    await _pumpHome(tester, usecase);
    expect(usecase.calls, hasLength(1));

    await _scrollToEnd(tester);

    expect(usecase.calls.map((params) => params.after), [null, '1', '2']);
    // Toutes les pages d'une session lisent le fil figé au même instant.
    expect(usecase.calls.map((params) => params.feedStartedAt).toSet(), hasLength(1));
    final state = _containerOf(tester).read(homeFeedNotifierProvider).value!;
    expect(state.contents, hasLength(90));
    expect(state.hasMore, isFalse);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Titre c29'), findsOneWidget);
  });

  testWidgets('un contenu déjà affiché qui revient dans la page suivante n\'est pas répété', (tester) async {
    final usecase = _PagedGetHomeFeedUsecase([
      _buildPage('a', 10),
      [_buildDetailed('a3'), ..._buildPage('b', 3)],
    ]);
    await _pumpHome(tester, usecase);

    await _scrollToEnd(tester);

    final state = _containerOf(tester).read(homeFeedNotifierProvider).value!;
    final ids = [for (final detailed in state.contents) detailed.content.id];
    expect(ids, hasLength(13));
    expect(ids.toSet(), hasLength(13));
    expect(ids.where((id) => id == 'a3'), hasLength(1));
  });

  testWidgets('l\'échec d\'une page suivante garde la liste et propose de réessayer', (tester) async {
    final usecase = _PagedGetHomeFeedUsecase([_buildPage('a', 10), _buildPage('b', 10)]);
    usecase.failingCursors.add('1');
    await _pumpHome(tester, usecase);

    await _scrollToEnd(tester);

    final container = _containerOf(tester);
    final failedState = container.read(homeFeedNotifierProvider).value!;
    expect(failedState.contents, hasLength(10));
    expect(failedState.loadMoreFailureMessage, isNotNull);
    expect(failedState.isLoadingMore, isFalse);
    // Pas de relance en boucle : la page en échec n'a été demandée qu'une fois.
    expect(usecase.calls.where((params) => params.after == '1'), hasLength(1));
    expect(find.text('Titre a9'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);

    await tester.tap(find.text('Réessayer'));
    await tester.pump();
    await tester.pump();
    await _scrollToEnd(tester);

    final state = container.read(homeFeedNotifierProvider).value!;
    expect(state.contents, hasLength(20));
    expect(state.loadMoreFailureMessage, isNull);
    expect(find.text('Titre b9'), findsOneWidget);
  });

  testWidgets('recharger le fil ouvre une nouvelle session et repart de la première page', (tester) async {
    final usecase = _PagedGetHomeFeedUsecase([_buildPage('a', 30), _buildPage('b', 30)]);
    await _pumpHome(tester, usecase);
    await _scrollToEnd(tester);
    final container = _containerOf(tester);
    expect(container.read(homeFeedNotifierProvider).value!.contents, hasLength(60));

    // Laisse passer un peu de temps réel, pour que la nouvelle session commence après la première.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    final callCountBeforeRefresh = usecase.calls.length;
    await container.read(homeFeedNotifierProvider.notifier).refresh();

    final refreshCall = usecase.calls[callCountBeforeRefresh];
    expect(refreshCall.after, isNull);
    expect(refreshCall.feedStartedAt.isAfter(usecase.calls.first.feedStartedAt), isTrue);
    final refreshedState = container.read(homeFeedNotifierProvider).value!;
    expect(refreshedState.contents, hasLength(30));
    expect(refreshedState.feedStartedAt, refreshCall.feedStartedAt);
    expect(refreshedState.hasMore, isTrue);

    // La liste, restée en bas, redemande aussitôt la suite : sur la nouvelle session.
    await tester.pump();
    await tester.pump();
    final laterCalls = usecase.calls.skip(callCountBeforeRefresh);
    expect(laterCalls.map((params) => params.feedStartedAt).toSet(), {refreshCall.feedStartedAt});
  });

  testWidgets('une tuile affiche l\'auteur et le nombre de réactions lus avec le contenu', (tester) async {
    final author = Signature(
      id: 'author',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      pseudo: 'auteur',
      avatarFrames: const ['(o_O)'],
    );
    final usecase = _PagedGetHomeFeedUsecase([
      [_buildDetailed('1', signature: author, reactionCount: 7)],
    ]);
    await _pumpHome(tester, usecase);

    final tile = find.byType(ContentWidget);
    expect(find.descendant(of: tile, matching: find.text('(o_O)')), findsWidgets);
    expect(find.descendant(of: tile, matching: find.text('7')), findsWidgets);
  });

  testWidgets('réagir à un contenu met à jour son nombre de réactions sans relire le fil', (tester) async {
    final usecase = _PagedGetHomeFeedUsecase([
      [_buildDetailed('1', reactionCount: 2), _buildDetailed('2', reactionCount: 5)],
    ]);
    await _pumpHome(
      tester,
      usecase,
      overrides: [
        saveReactionUsecaseProvider.overrideWithValue(_FakeSaveReactionUsecase()),
        countContentReactionsUsecaseProvider.overrideWithValue(_FakeCountContentReactionsUsecase(3)),
      ],
    );
    expect(find.text('2'), findsWidgets);

    final container = _containerOf(tester);
    final subscription = container.listen(reactionComposerSheetNotifierProvider, (_, _) {});
    final failureMessage = await container
        .read(reactionComposerSheetNotifierProvider.notifier)
        .save(
          contentId: '1',
          avatarFrames: const ['(^_^)'],
          colorArgb: 0xFF000000,
          ghostSpeed: 1,
          avatarFrameSpeed: 1,
          bubbleText: 'bravo',
          bubbleFont: TextFont.standard,
        );
    subscription.close();
    await tester.pump();

    expect(failureMessage, isNull);
    final contents = container.read(homeFeedNotifierProvider).value!.contents;
    expect(contents.first.reactionCount, 3);
    expect(contents.last.reactionCount, 5);
    expect(find.text('3'), findsWidgets);
    expect(find.text('2'), findsNothing);
    expect(usecase.calls, hasLength(1));
  });
}
