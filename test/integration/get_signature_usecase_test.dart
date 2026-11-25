import 'package:bedbug/infra/resources/signature/signature/signature.config.dart';
import 'package:bedbug/logic/usecases/signature/get_signature/get_signature.params.dart';
import 'package:bedbug/logic/usecases/signature/get_signature/get_signature.usecase.dart';
import 'package:bedbug/logic/usecases/signature/save_local_signature/save_local_signature.params.dart';
import 'package:bedbug/logic/usecases/signature/save_local_signature/save_local_signature.usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/drift_test_helper.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = createTestContainer();
  });

  tearDown(() {
    container.dispose();
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
        avatarFrames: ['ʕ•ᴥ•ʔ'],
        colorArgb: null,
        ghostSpeed: 2,
        socialLinks: {},
      ),
    );

    final result = await container.read(getSignatureUsecaseProvider)(
      const GetSignatureParams(signatureId: localSignatureId),
    );

    expect(result.right!.pseudo, 'bedbug');
    expect(result.right!.avatarFrames, ['ʕ•ᴥ•ʔ']);
  });
}
