import 'dart:io';

import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:bedbug/features/signature/domain/enums/social_network.dart';
import 'package:bedbug/features/signature/domain/usecases/get_local_signature_usecase.dart';
import 'package:bedbug/features/signature/domain/usecases/save_local_signature_usecase.dart';
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
    final result = await container.read(getLocalSignatureUsecaseProvider)(const NoParams());

    expect(result.isSuccess, isTrue);
    expect(result.right, isNull);
  });

  test('save normalise le profil puis get le relit depuis le vrai repository Hive', () async {
    final saveResult = await container.read(saveLocalSignatureUsecaseProvider)(
      const SaveLocalSignatureParams(
        pseudo: '  bed-bug  ',
        avatarText: '(◕‿◕)',
        colorArgb: 0xFF123456,
        ghostSpeed: 99,
        socialLinks: {SocialNetwork.twitch: 'https://www.twitch.tv/bedbug', SocialNetwork.github: '   '},
      ),
    );
    expect(saveResult.isSuccess, isTrue);

    final signature = (await container.read(getLocalSignatureUsecaseProvider)(const NoParams())).right!;
    expect(signature.pseudo, 'bed-bug');
    expect(signature.colorArgb, 0xFF123456);
    expect(signature.ghostSpeed, maxGhostSpeed);
    expect(signature.socialLinks, {SocialNetwork.twitch: 'bedbug'});
  });

  test('save refuse un pseudo ou une icône hors règles', () async {
    final saveUsecase = container.read(saveLocalSignatureUsecaseProvider);

    final invalidPseudo = await saveUsecase(
      const SaveLocalSignatureParams(
        pseudo: 'bed bug',
        avatarText: '(◕‿◕)',
        colorArgb: null,
        ghostSpeed: 1,
        socialLinks: {},
      ),
    );
    final invalidAvatar = await saveUsecase(
      const SaveLocalSignatureParams(
        pseudo: 'bedbug',
        avatarText: 'coucou',
        colorArgb: null,
        ghostSpeed: 1,
        socialLinks: {},
      ),
    );

    expect(invalidPseudo.left, SaveLocalSignatureFailure.invalidProfile);
    expect(invalidAvatar.left, SaveLocalSignatureFailure.invalidProfile);
  });
}
