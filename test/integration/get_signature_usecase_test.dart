import 'dart:io';

import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:bedbug/features/signature/domain/repositories/signature_repository.dart';
import 'package:bedbug/features/signature/domain/usecases/get_signature_usecase.dart';
import 'package:bedbug/features/signature/domain/usecases/save_local_signature_usecase.dart';
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
    final result = await container.read(getSignatureUsecaseProvider)(
      const GetSignatureParams(signatureId: anonymousSignatureId),
    );

    expect(result.right, same(anonymousSignature));
    expect(result.right!.pseudo, 'anonyme');
    expect(result.right!.socialLinks, isEmpty);
  });

  test("un auteur inconnu de l'appareil est présenté comme anonyme", () async {
    final result = await container.read(getSignatureUsecaseProvider)(
      const GetSignatureParams(signatureId: 'seed-author-3'),
    );

    expect(result.right, same(anonymousSignature));
  });

  test("l'utilisateur du téléphone est présenté avec son profil enregistré", () async {
    await container.read(saveLocalSignatureUsecaseProvider)(
      const SaveLocalSignatureParams(
        pseudo: 'bedbug',
        avatarText: 'ʕ•ᴥ•ʔ',
        colorArgb: null,
        ghostSpeed: 2,
        socialLinks: {},
      ),
    );

    final result = await container.read(getSignatureUsecaseProvider)(
      const GetSignatureParams(signatureId: localSignatureId),
    );

    expect(result.right!.pseudo, 'bedbug');
    expect(result.right!.avatarText, 'ʕ•ᴥ•ʔ');
  });
}
