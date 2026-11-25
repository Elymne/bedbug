import 'package:bedbug/application/notifiers/reaction_count_changes.notifier.dart';
import 'package:bedbug/application/notifiers/search_results.notifier.dart';
import 'package:bedbug/core/domain/cursor_page.dart';
import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/infra/resources/content/content/content.entity.detailed.dart';
import 'package:bedbug/infra/resources/content/content/content_origin.enum.dart';
import 'package:bedbug/infra/resources/content/content/text_content.entity.dart';
import 'package:bedbug/logic/usecases/feed/get_filtered_contents/get_filtered_contents.failure.dart';
import 'package:bedbug/logic/usecases/feed/get_filtered_contents/get_filtered_contents.params.dart';
import 'package:bedbug/logic/usecases/feed/get_filtered_contents/get_filtered_contents.usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/drift_test_helper.dart';

/// Fake [GetFilteredContentsUsecase] servant deux pages, la seconde reprenant un contenu de la première.
class _PagedGetFilteredContentsUsecase implements GetFilteredContentsUsecase {
  /// Indique si le prochain appel pour la seconde page échoue.
  bool isNextPageFailing = false;

  /// Curseurs reçus, dans l'ordre des appels.
  final List<String?> cursors = [];

  @override
  Future<Either<GetFilteredContentsFailure, CursorPage<ContentDetailed>>> call(GetFilteredContentsParams params) async {
    cursors.add(params.after);
    if (params.after == null) {
      return Right(CursorPage(items: [_buildDetailed('1'), _buildDetailed('2')], nextCursor: 'next'));
    }
    if (isNextPageFailing) {
      return const Left(GetFilteredContentsFailure.storageError);
    }
    return Right(CursorPage(items: [_buildDetailed('2'), _buildDetailed('3')], nextCursor: null));
  }
}

/// Construit un résultat de recherche d'identifiant [id], sans réaction.
///
/// - [id] : identifiant du contenu.
ContentDetailed _buildDetailed(String id) {
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
    signature: null,
    reactionCount: 0,
    isViewed: true,
  );
}

void main() {
  const criteria = QuerySearchCriteria('titre');

  test('la page suivante s\'ajoute sans doublon, puis plus rien n\'est demandé', () async {
    final usecase = _PagedGetFilteredContentsUsecase();
    final container = createTestContainer(overrides: [getFilteredContentsUsecaseProvider.overrideWithValue(usecase)]);
    addTearDown(container.dispose);
    final subscription = container.listen(searchResultsNotifierProvider(criteria), (_, _) {});
    addTearDown(subscription.close);

    await container.read(searchResultsNotifierProvider(criteria).future);
    await container.read(searchResultsNotifierProvider(criteria).notifier).loadMore();
    await container.read(searchResultsNotifierProvider(criteria).notifier).loadMore();

    final state = container.read(searchResultsNotifierProvider(criteria)).value!;
    expect([for (final detailed in state.contents) detailed.content.id], ['1', '2', '3']);
    expect(state.hasMore, isFalse);
    expect(usecase.cursors, [null, 'next']);
  });

  test('l\'échec de la page suivante garde les résultats affichés', () async {
    final usecase = _PagedGetFilteredContentsUsecase()..isNextPageFailing = true;
    final container = createTestContainer(overrides: [getFilteredContentsUsecaseProvider.overrideWithValue(usecase)]);
    addTearDown(container.dispose);
    final subscription = container.listen(searchResultsNotifierProvider(criteria), (_, _) {});
    addTearDown(subscription.close);

    await container.read(searchResultsNotifierProvider(criteria).future);
    await container.read(searchResultsNotifierProvider(criteria).notifier).loadMore();

    final state = container.read(searchResultsNotifierProvider(criteria)).value!;
    expect(state.contents, hasLength(2));
    expect(state.hasMore, isTrue);
    expect(state.isLoadingMore, isFalse);
    expect(state.loadMoreFailureMessage, 'Impossible d\'accéder au stockage local.');
  });

  test('un nouveau nombre de réactions corrige le seul résultat concerné', () async {
    final usecase = _PagedGetFilteredContentsUsecase();
    final container = createTestContainer(overrides: [getFilteredContentsUsecaseProvider.overrideWithValue(usecase)]);
    addTearDown(container.dispose);
    final subscription = container.listen(searchResultsNotifierProvider(criteria), (_, _) {});
    addTearDown(subscription.close);
    await container.read(searchResultsNotifierProvider(criteria).future);

    container.read(reactionCountChangesNotifierProvider.notifier).publish(contentId: '2', reactionCount: 4);

    final state = container.read(searchResultsNotifierProvider(criteria)).value!;
    expect([for (final detailed in state.contents) detailed.reactionCount], [0, 4]);
    expect(usecase.cursors, [null]);
  });
}
