import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/infra/resources/content/content/content_origin.enum.dart';
import 'package:bedbug/infra/resources/content/content/text_content.entity.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.entity.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.repository.drift.dart';
import 'package:bedbug/infra/resources/content/seen_content/seen_content.repository.drift.dart';
import 'package:bedbug/logic/usecases/content/delete_own_content/delete_own_content.failure.dart';
import 'package:bedbug/logic/usecases/content/delete_own_content/delete_own_content.params.dart';
import 'package:bedbug/logic/usecases/content/delete_own_content/delete_own_content.usecase.dart';
import 'package:bedbug/logic/usecases/content/get_own_contents/get_own_contents.usecase.dart';
import 'package:bedbug/logic/usecases/content/save_content/save_content.params.dart';
import 'package:bedbug/logic/usecases/content/save_content/save_content.usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/drift_test_helper.dart';
import '../helpers/seed_contents_usecase.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    container = createTestContainer();
  });

  tearDown(() async {
    container.dispose();
  });

  test('mes posts regroupent mes contenus, anonymes compris, du plus récent au plus ancien', () async {
    final saveUsecase = container.read(saveContentUsecaseProvider);
    await saveUsecase(SaveContentParams(content: _buildTextContent('ancien', ContentOrigin.owned, DateTime(2026))));
    await saveUsecase(
      SaveContentParams(
        content: _buildTextContent('anonyme', ContentOrigin.owned, DateTime(2026, 2), signatureId: 'anonymous'),
      ),
    );
    await saveUsecase(SaveContentParams(content: _buildTextContent('recu', ContentOrigin.public, DateTime(2026, 3))));

    final result = await container.read(getOwnContentsUsecaseProvider)(const NoParams());

    expect(result.right!.map((detailed) => detailed.content.id), ['anonyme', 'ancien']);
  });

  test('supprimer un de mes posts le retire avec ses réactions, et le mémorise comme déjà vu', () async {
    final saveUsecase = container.read(saveContentUsecaseProvider);
    await saveUsecase(SaveContentParams(content: _buildTextContent('mien', ContentOrigin.owned, DateTime(2026))));
    await container
        .read(reactionRepositoryProvider)
        .addOne(
          Reaction(
            id: 'reaction',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
            contentId: 'mien',
            authorId: 'pair',
            avatarFrames: const ['(◕‿◕)'],
            bubbleText: 'ok',
          ),
        );

    final result = await container.read(deleteOwnContentUsecaseProvider)(
      const DeleteOwnContentParams(contentId: 'mien'),
    );

    expect(result.isSuccess, isTrue);
    expect((await container.read(getOwnContentsUsecaseProvider)(const NoParams())).right, isEmpty);
    expect(await container.read(reactionRepositoryProvider).getAllByContentId('mien'), isEmpty);
    expect(await container.read(seenContentRepositoryProvider).getSeenAmong({'mien'}), {'mien'});
  });

  test("refuse de supprimer un contenu reçu d'un pair, ou introuvable", () async {
    await container.read(saveContentUsecaseProvider)(
      SaveContentParams(content: _buildTextContent('recu', ContentOrigin.public, DateTime(2026))),
    );
    final deleteUsecase = container.read(deleteOwnContentUsecaseProvider);

    final notOwned = await deleteUsecase(const DeleteOwnContentParams(contentId: 'recu'));
    final notFound = await deleteUsecase(const DeleteOwnContentParams(contentId: 'inexistant'));

    expect(notOwned.left, DeleteOwnContentFailure.notOwned);
    expect(notFound.left, DeleteOwnContentFailure.notFound);
  });

  test('les contenus factices ne passent jamais pour les miens', () async {
    await container.read(seedContentsUsecaseProvider)(const SeedContentsParams(count: 50));

    final result = await container.read(getOwnContentsUsecaseProvider)(const NoParams());

    expect(result.right, isEmpty);
  });
}

TextContent _buildTextContent(String id, ContentOrigin origin, DateTime createdAt, {String signatureId = 'local'}) {
  return TextContent(
    id: id,
    createdAt: createdAt,
    updatedAt: createdAt,
    signatureId: signatureId,
    flair: 'test',
    origin: origin,
    broadcastScore: 1,
    survivalScore: 1,
    displayScore: 1,
    bounce: 0,
    sizeInBytes: 10,
    title: 'Titre $id',
    body: 'Corps $id',
  );
}
