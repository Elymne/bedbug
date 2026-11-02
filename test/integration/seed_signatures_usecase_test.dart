import 'dart:io';

import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/resources/signature/signature.entity.dart';
import 'package:bedbug/resources/signature/signature.repository.hive.dart';
import 'package:bedbug/resources/signature/signature_text.extension.dart';
import 'package:bedbug/usecases/feed/get_home_feed/get_home_feed.usecase.dart';
import 'package:bedbug/usecases/signature/get_local_signature/get_local_signature.usecase.dart';
import 'package:bedbug/usecases/signature/get_signature_suggestions/get_signature_suggestions.params.dart';
import 'package:bedbug/usecases/signature/get_signature_suggestions/get_signature_suggestions.usecase.dart';
import 'package:bedbug/usecases/signature/save_local_signature/save_local_signature.params.dart';
import 'package:bedbug/usecases/signature/save_local_signature/save_local_signature.usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/hive_test_helper.dart';
import '../helpers/seed_contents_usecase.dart';
import '../helpers/seed_signatures_usecase.dart';

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
    final result = await container.read(seedSignaturesUsecaseProvider)(const SeedSignaturesParams(randomSeed: 42));
    final signatureIds = result.right!;
    expect(signatureIds, hasLength(5));

    final repository = container.read(signatureRepositoryProvider);
    for (final signatureId in signatureIds) {
      final signature = (await repository.getById(signatureId))!;
      expect(signature.pseudo.isValidPseudo, isTrue, reason: signature.pseudo);
      expect(signature.avatarText.isValidAvatarText, isTrue, reason: signature.avatarText);
      for (final entry in signature.socialLinks.entries) {
        expect(entry.key.normalizeHandle(entry.value), entry.value);
      }
    }

    final firstSignature = (await repository.getById(signatureIds.first))!;
    final suggestions = await container.read(getSignatureSuggestionsUsecaseProvider)(
      GetSignatureSuggestionsParams(input: firstSignature.pseudo.substring(0, 3)),
    );
    expect(suggestions.right!.map((signature) => signature.id), contains(firstSignature.id));
  });

  test('relancer le seed remplace les utilisateurs factices sans toucher au profil local', () async {
    await container.read(saveLocalSignatureUsecaseProvider)(
      const SaveLocalSignatureParams(
        pseudo: 'moi',
        avatarText: '(◕‿◕)',
        colorArgb: null,
        ghostSpeed: 1,
        socialLinks: {},
      ),
    );
    final seedUsecase = container.read(seedSignaturesUsecaseProvider);

    await seedUsecase(const SeedSignaturesParams(randomSeed: 1));
    await seedUsecase(const SeedSignaturesParams(randomSeed: 2));

    expect(container.read(hiveSignatureBoxProvider).length, 6);
    final localSignature = await container.read(getLocalSignatureUsecaseProvider)(const NoParams());
    expect(localSignature.right!.pseudo, 'moi');
  });

  test('les contenus factices sont répartis entre les auteurs fournis', () async {
    final signatureIds = (await container.read(seedSignaturesUsecaseProvider)(
      const SeedSignaturesParams(randomSeed: 7),
    )).right!;
    final allSignatureIds = [...signatureIds, anonymousSignatureId];

    await container.read(seedContentsUsecaseProvider)(
      SeedContentsParams(count: 200, signatureIds: allSignatureIds, randomSeed: 7),
    );

    final contents = (await container.read(getHomeFeedUsecaseProvider)(const NoParams())).right!.contents;
    final usedSignatureIds = contents.map((content) => content.signatureId).toSet();
    expect(usedSignatureIds, allSignatureIds.toSet());
  });
}
