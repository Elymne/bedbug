import 'dart:io';

import 'package:bedbug/features/user/domain/entities/anonymous_user.dart';
import 'package:bedbug/features/user/domain/repositories/user_repository.dart';
import 'package:bedbug/features/user/domain/usecases/get_author_usecase.dart';
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

  test('un contenu anonyme est présenté avec le profil anonyme codé en dur', () async {
    final result = await container.read(getAuthorUsecaseProvider)(const GetAuthorParams(authorId: anonymousUserId));

    expect(result.right, same(anonymousUser));
    expect(result.right!.pseudo, 'anonyme');
    expect(result.right!.socialLinks, isEmpty);
  });

  test("un auteur inconnu de l'appareil est présenté comme anonyme", () async {
    final result = await container.read(getAuthorUsecaseProvider)(const GetAuthorParams(authorId: 'seed-author-3'));

    expect(result.right, same(anonymousUser));
  });

  test("l'utilisateur du téléphone est présenté avec son profil enregistré", () async {
    await container.read(saveLocalUserUsecaseProvider)(
      const SaveLocalUserParams(pseudo: 'bedbug', avatarText: 'ʕ•ᴥ•ʔ', colorArgb: null, ghostSpeed: 2, socialLinks: {}),
    );

    final result = await container.read(getAuthorUsecaseProvider)(const GetAuthorParams(authorId: localUserId));

    expect(result.right!.pseudo, 'bedbug');
    expect(result.right!.avatarText, 'ʕ•ᴥ•ʔ');
  });
}
