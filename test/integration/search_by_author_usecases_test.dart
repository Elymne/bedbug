import 'dart:io';

import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/usecases/get_contents_by_author_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/save_content_usecase.dart';
import 'package:bedbug/features/user/domain/entities/anonymous_user.dart';
import 'package:bedbug/features/user/domain/repositories/user_repository.dart';
import 'package:bedbug/features/user/domain/usecases/get_user_suggestions_usecase.dart';
import 'package:bedbug/features/user/domain/usecases/save_local_user_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/hive_test_helper.dart';

void main() {
  late Directory tempDir;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await openTestHive();
    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    await closeTestHive(tempDir);
  });

  group('suggestions d\'utilisateurs', () {
    setUp(() async {
      await container.read(saveLocalUserUsecaseProvider)(
        const SaveLocalUserParams(
          pseudo: 'Bedbug',
          avatarText: '(◕‿◕)',
          colorArgb: null,
          ghostSpeed: 1,
          socialLinks: {},
        ),
      );
    });

    test('propose les utilisateurs dont le pseudo commence par la saisie, sans tenir compte de la casse', () async {
      final result = await container.read(getUserSuggestionsUsecaseProvider)(
        const GetUserSuggestionsParams(input: 'bed'),
      );

      expect(result.right!.map((user) => user.pseudo), ['Bedbug']);
    });

    test('accepte une saisie préfixée de u/', () async {
      final result = await container.read(getUserSuggestionsUsecaseProvider)(
        const GetUserSuggestionsParams(input: 'u/BED'),
      );

      expect(result.right, hasLength(1));
    });

    test('ne propose rien pour une saisie vide ou sans correspondance', () async {
      final usecase = container.read(getUserSuggestionsUsecaseProvider);

      expect((await usecase(const GetUserSuggestionsParams(input: '  '))).right, isEmpty);
      expect((await usecase(const GetUserSuggestionsParams(input: 'zzz'))).right, isEmpty);
    });

    test('ne propose jamais le profil anonyme, même en tapant son pseudo', () async {
      final result = await container.read(getUserSuggestionsUsecaseProvider)(
        const GetUserSuggestionsParams(input: 'anon'),
      );

      expect(result.right, isEmpty);
    });
  });

  test("les contenus d'un auteur excluent ses contenus anonymes et ceux des autres", () async {
    final saveUsecase = container.read(saveContentUsecaseProvider);
    await saveUsecase(SaveContentParams(content: _buildTextContent('signe', localUserId)));
    await saveUsecase(SaveContentParams(content: _buildTextContent('anonyme', anonymousUserId)));
    await saveUsecase(SaveContentParams(content: _buildTextContent('autre', 'seed-author-1')));

    final result = await container.read(getContentsByAuthorUsecaseProvider)(
      const GetContentsByAuthorParams(authorId: localUserId),
    );

    expect(result.right!.map((content) => content.id), ['signe']);
  });
}

TextContent _buildTextContent(String id, String authorId) {
  return TextContent(
    id: id,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    authorId: authorId,
    senderId: 'local',
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
