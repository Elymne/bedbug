import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.drift.dart';
import 'package:bedbug/infra/resources/drift.database.dart';
import 'package:bedbug/infra/resources/signature/signature/signature.config.dart';
import 'package:bedbug/infra/resources/signature/signature/signature.entity.dart';
import 'package:bedbug/infra/resources/signature/signature/signature.repository.drift.dart';
import 'package:bedbug/logic/usecases/signature/get_local_signature/get_local_signature.usecase.dart';
import 'package:bedbug/logic/usecases/signature/get_signature_suggestions/get_signature_suggestions.params.dart';
import 'package:bedbug/logic/usecases/signature/get_signature_suggestions/get_signature_suggestions.usecase.dart';
import 'package:bedbug/logic/usecases/signature/save_local_signature/save_local_signature.params.dart';
import 'package:bedbug/logic/usecases/signature/save_local_signature/save_local_signature.usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/drift_test_helper.dart';
import '../helpers/seed_contents_usecase.dart';
import '../helpers/seed_signatures_usecase.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    container = createTestContainer();
  });

  tearDown(() async {
    container.dispose();
  });

  test('génère 5 utilisateurs aux profils valides, trouvables par la recherche', () async {
    final result = await container.read(seedSignaturesUsecaseProvider)(const SeedSignaturesParams(randomSeed: 42));
    final signatureIds = result.right!;
    expect(signatureIds, hasLength(5));

    final repository = container.read(signatureRepositoryProvider);
    for (final signatureId in signatureIds) {
      final signature = (await repository.getById(signatureId))!;
      expect(Signature.isValidPseudo(signature.pseudo), isTrue, reason: signature.pseudo);
      expect(Signature.isValidAvatarFrames(signature.avatarFrames), isTrue, reason: '${signature.avatarFrames}');
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
        avatarFrames: ['(◕‿◕)'],
        colorArgb: null,
        ghostSpeed: 1,
        socialLinks: {},
      ),
    );
    final seedUsecase = container.read(seedSignaturesUsecaseProvider);

    await seedUsecase(const SeedSignaturesParams(randomSeed: 1));
    await seedUsecase(const SeedSignaturesParams(randomSeed: 2));

    final database = container.read(appDatabaseProvider);
    expect(await database.select(database.signatures).get(), hasLength(6));
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

    final contents = await container.read(contentRepositoryProvider).getAll();
    final usedSignatureIds = contents.map((content) => content.signatureId).toSet();
    expect(usedSignatureIds, allSignatureIds.toSet());
  });
}
