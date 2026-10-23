import 'dart:io';

import 'package:bedbug/features/content/domain/usecases/get_home_feed_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/seed_contents_usecase.dart';
import 'package:bedbug/features/user/domain/entities/anonymous_user.dart';
import 'package:bedbug/features/user/domain/extensions/profile_text_extension.dart';
import 'package:bedbug/features/user/domain/usecases/get_local_user_usecase.dart';
import 'package:bedbug/features/user/domain/usecases/get_user_suggestions_usecase.dart';
import 'package:bedbug/features/user/domain/usecases/save_local_user_usecase.dart';
import 'package:bedbug/features/user/domain/usecases/seed_users_usecase.dart';
import 'package:bedbug/features/user/infrastructure/datasources/hive_user_repository.dart';
import 'package:bedbug/shared/domain/params.dart';
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

  test('génère 5 utilisateurs aux profils valides, trouvables par la recherche', () async {
    final result = await container.read(seedUsersUsecaseProvider)(const SeedUsersParams(randomSeed: 42));
    final userIds = result.right!;
    expect(userIds, hasLength(5));

    final repository = container.read(userRepositoryProvider);
    for (final userId in userIds) {
      final user = (await repository.getById(userId))!;
      expect(user.pseudo.isValidPseudo, isTrue, reason: user.pseudo);
      expect(user.avatarText.isValidAvatarText, isTrue, reason: user.avatarText);
      for (final entry in user.socialLinks.entries) {
        expect(entry.key.normalizeHandle(entry.value), entry.value);
      }
    }

    final firstUser = (await repository.getById(userIds.first))!;
    final suggestions = await container.read(getUserSuggestionsUsecaseProvider)(
      GetUserSuggestionsParams(input: firstUser.pseudo.substring(0, 3)),
    );
    expect(suggestions.right!.map((user) => user.id), contains(firstUser.id));
  });

  test('relancer le seed remplace les utilisateurs factices sans toucher au profil local', () async {
    await container.read(saveLocalUserUsecaseProvider)(
      const SaveLocalUserParams(pseudo: 'moi', avatarText: '(◕‿◕)', colorArgb: null, ghostSpeed: 1, socialLinks: {}),
    );
    final seedUsecase = container.read(seedUsersUsecaseProvider);

    await seedUsecase(const SeedUsersParams(randomSeed: 1));
    await seedUsecase(const SeedUsersParams(randomSeed: 2));

    expect(container.read(hiveUserBoxProvider).length, 6);
    final localUser = await container.read(getLocalUserUsecaseProvider)(const NoParams());
    expect(localUser.right!.pseudo, 'moi');
  });

  test('les contenus factices sont répartis entre les auteurs fournis', () async {
    final userIds = (await container.read(seedUsersUsecaseProvider)(const SeedUsersParams(randomSeed: 7))).right!;
    final authorIds = [...userIds, anonymousUserId];

    await container.read(seedContentsUsecaseProvider)(
      SeedContentsParams(count: 200, authorIds: authorIds, randomSeed: 7),
    );

    final contents = (await container.read(getHomeFeedUsecaseProvider)(const NoParams())).right!;
    final usedAuthorIds = contents.map((content) => content.authorId).toSet();
    expect(usedAuthorIds, authorIds.toSet());
  });
}
