import 'dart:io';

import 'package:bedbug/features/user/domain/entities/user.dart';
import 'package:bedbug/features/user/domain/enums/social_network.dart';
import 'package:bedbug/features/user/domain/usecases/get_local_user_usecase.dart';
import 'package:bedbug/features/user/domain/usecases/save_local_user_usecase.dart';
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

  test('get retourne null tant que le profil n\'a jamais été enregistré', () async {
    final result = await container.read(getLocalUserUsecaseProvider)(const NoParams());

    expect(result.isSuccess, isTrue);
    expect(result.right, isNull);
  });

  test('save normalise le profil puis get le relit depuis le vrai repository Hive', () async {
    final saveResult = await container.read(saveLocalUserUsecaseProvider)(
      const SaveLocalUserParams(
        pseudo: '  bed-bug  ',
        avatarText: '(◕‿◕)',
        colorArgb: 0xFF123456,
        ghostSpeed: 99,
        socialLinks: {SocialNetwork.twitch: 'https://www.twitch.tv/bedbug', SocialNetwork.github: '   '},
      ),
    );
    expect(saveResult.isSuccess, isTrue);

    final user = (await container.read(getLocalUserUsecaseProvider)(const NoParams())).right!;
    expect(user.pseudo, 'bed-bug');
    expect(user.colorArgb, 0xFF123456);
    expect(user.ghostSpeed, maxGhostSpeed);
    expect(user.socialLinks, {SocialNetwork.twitch: 'bedbug'});
  });

  test('save refuse un pseudo ou une icône hors règles', () async {
    final saveUsecase = container.read(saveLocalUserUsecaseProvider);

    final invalidPseudo = await saveUsecase(
      const SaveLocalUserParams(
        pseudo: 'bed bug',
        avatarText: '(◕‿◕)',
        colorArgb: null,
        ghostSpeed: 1,
        socialLinks: {},
      ),
    );
    final invalidAvatar = await saveUsecase(
      const SaveLocalUserParams(
        pseudo: 'bedbug',
        avatarText: 'coucou',
        colorArgb: null,
        ghostSpeed: 1,
        socialLinks: {},
      ),
    );

    expect(invalidPseudo.left, SaveLocalUserFailure.invalidProfile);
    expect(invalidAvatar.left, SaveLocalUserFailure.invalidProfile);
  });
}
