import 'package:bedbug/application/screens/signature/signature.screen.dart';
import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/resources/content/content/content.entity.dart';
import 'package:bedbug/resources/content/content/content_origin.enum.dart';
import 'package:bedbug/resources/content/content/text_content.entity.dart';
import 'package:bedbug/resources/signature/signature/signature.entity.dart';
import 'package:bedbug/resources/signature/signature/social_network.enum.dart';
import 'package:bedbug/usecases/feed/get_contents_by_signatures/get_contents_by_signatures.failure.dart';
import 'package:bedbug/usecases/feed/get_contents_by_signatures/get_contents_by_signatures.params.dart';
import 'package:bedbug/usecases/feed/get_contents_by_signatures/get_contents_by_signatures.usecase.dart';
import 'package:bedbug/usecases/signature/get_signature/get_signature.failure.dart';
import 'package:bedbug/usecases/signature/get_signature/get_signature.params.dart';
import 'package:bedbug/usecases/signature/get_signature/get_signature.usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

/// Fake [GetSignatureUsecase] retournant toujours le même profil.
class _FakeGetSignatureUsecase implements GetSignatureUsecase {
  @override
  Future<Either<GetSignatureFailure, Signature>> call(GetSignatureParams params) async {
    return Right(
      Signature(
        id: params.signatureId,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        pseudo: 'Punaise-Royale',
        avatarText: 'ʕ•ᴥ•ʔ',
        socialLinks: const {SocialNetwork.github: 'punaise-royale'},
      ),
    );
  }
}

/// Fake [GetContentsBySignaturesUsecase] retournant un unique contenu de l'auteur demandé.
class _FakeGetContentsBySignaturesUsecase implements GetContentsBySignaturesUsecase {
  @override
  Future<Either<GetContentsBySignaturesFailure, List<Content>>> call(GetContentsBySignaturesParams params) async {
    return Right([
      TextContent(
        id: 'post',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        signatureId: params.signatureIds.first,
        flair: 'literie',
        origin: ContentOrigin.public,
        broadcastScore: 1,
        survivalScore: 1,
        displayScore: 1,
        bounce: 0,
        sizeInBytes: 10,
        title: 'Mon premier post',
        body: 'Corps',
      ),
    ]);
  }
}

void main() {
  testWidgets('affiche la signature en tête, puis les contenus qu\'elle a signés', (tester) async {
    await pumpApp(
      tester,
      const SignatureScreen(signatureId: 'seed-signature-0'),
      overrides: [
        getSignatureUsecaseProvider.overrideWithValue(_FakeGetSignatureUsecase()),
        getContentsBySignaturesUsecaseProvider.overrideWithValue(_FakeGetContentsBySignaturesUsecase()),
      ],
    );
    // Le bedbug s'anime en boucle : on avance le temps au lieu d'attendre une
    // stabilisation qui n'arrivera jamais.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Le préfixe est rendu à part, pour son effet ghost : le nom complet n'existe que dans le libellé accessible.
    expect(find.bySemanticsLabel('s/Punaise-Royale'), findsOneWidget);
    expect(find.text('GitHub'), findsOneWidget);
    expect(find.text('Mon premier post'), findsOneWidget);
  });
}
