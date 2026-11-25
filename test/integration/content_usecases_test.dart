import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/infra/resources/content/content/content_origin.enum.dart';
import 'package:bedbug/infra/resources/content/content/text_content.entity.dart';
import 'package:bedbug/logic/usecases/content/clear_contents/clear_contents.usecase.dart';
import 'package:bedbug/logic/usecases/content/save_content/save_content.params.dart';
import 'package:bedbug/logic/usecases/content/save_content/save_content.usecase.dart';
import 'package:bedbug/logic/usecases/feed/get_home_feed/get_home_feed.params.dart';
import 'package:bedbug/logic/usecases/feed/get_home_feed/get_home_feed.usecase.dart';
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

  test('save puis get retourne le contenu sauvegardé, via le vrai repository', () async {
    final saveUsecase = container.read(saveContentUsecaseProvider);
    final getUsecase = container.read(getHomeFeedUsecaseProvider);

    final saveResult = await saveUsecase(SaveContentParams(content: _buildTextContent('a')));
    expect(saveResult.isSuccess, isTrue);

    final getResult = await getUsecase(GetHomeFeedParams(feedStartedAt: DateTime.now()));
    expect(getResult.isSuccess, isTrue);
    final contents = getResult.right!.items;
    expect(contents, hasLength(1));
    expect((contents.single.content as TextContent).title, 'Titre a');
  });

  test('clear supprime tous les contenus stockés', () async {
    final saveUsecase = container.read(saveContentUsecaseProvider);
    final getUsecase = container.read(getHomeFeedUsecaseProvider);
    final clearUsecase = container.read(clearContentsUsecaseProvider);

    await saveUsecase(SaveContentParams(content: _buildTextContent('a')));
    await saveUsecase(SaveContentParams(content: _buildTextContent('b')));

    final clearResult = await clearUsecase(const NoParams());
    expect(clearResult.isSuccess, isTrue);

    final getResult = await getUsecase(GetHomeFeedParams(feedStartedAt: DateTime.now()));
    expect(getResult.right!.items, isEmpty);
  });

  test('seed insère le nombre de contenus demandé', () async {
    final seedUsecase = container.read(seedContentsUsecaseProvider);
    final getUsecase = container.read(getHomeFeedUsecaseProvider);

    final seedResult = await seedUsecase(const SeedContentsParams(count: 7));
    expect(seedResult.isSuccess, isTrue);

    final getResult = await getUsecase(GetHomeFeedParams(feedStartedAt: DateTime.now()));
    expect(getResult.right!.items, hasLength(7));
  });
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
