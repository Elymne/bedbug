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

  test('save enregistre la description sans espaces en bordure, et une description vide comme absente', () async {
    final saveUsecase = container.read(saveLocalSignatureUsecaseProvider);

    final withBio = await saveUsecase(
      const SaveLocalSignatureParams(
        pseudo: 'bedbug',
        avatarText: '(◕‿◕)',
        colorArgb: null,
        ghostSpeed: 1,
        socialLinks: {},
        bio: '  Je poste la nuit.  ',
      ),
    );
    final withBlankBio = await saveUsecase(
      const SaveLocalSignatureParams(
        pseudo: 'bedbug',
        avatarText: '(◕‿◕)',
        colorArgb: null,
        ghostSpeed: 1,
        socialLinks: {},
        bio: '   ',
      ),
    );

    expect(withBio.right?.bio, 'Je poste la nuit.');
    expect(withBlankBio.right?.bio, isNull);
    final reread = await container.read(getLocalSignatureUsecaseProvider)(const NoParams());
    expect(reread.right?.bio, isNull);
  });

  test('save refuse une description trop longue ou sur plusieurs lignes', () async {
    final saveUsecase = container.read(saveLocalSignatureUsecaseProvider);

    final tooLong = await saveUsecase(
      SaveLocalSignatureParams(
        pseudo: 'bedbug',
        avatarText: '(◕‿◕)',
        colorArgb: null,
        ghostSpeed: 1,
        socialLinks: const {},
        bio: 'a' * (maxSignatureBioLength + 1),
      ),
    );
    final multiline = await saveUsecase(
      const SaveLocalSignatureParams(
        pseudo: 'bedbug',
        avatarText: '(◕‿◕)',
        colorArgb: null,
        ghostSpeed: 1,
        socialLinks: {},
        bio: 'ligne 1\nligne 2',
      ),
    );

    expect(tooLong.left, SaveLocalSignatureFailure.invalidProfile);
    expect(multiline.left, SaveLocalSignatureFailure.invalidProfile);
  });
}
