import 'package:bedbug/application/screens/signature/signature.screen.dart';
import 'package:bedbug/core/domain/cursor_page.dart';
import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/infra/resources/content/content/content.entity.detailed.dart';
import 'package:bedbug/infra/resources/content/content/content_origin.enum.dart';
import 'package:bedbug/infra/resources/content/content/text_content.entity.dart';
import 'package:bedbug/infra/resources/signature/signature/signature.entity.dart';
import 'package:bedbug/infra/resources/signature/signature/social_network.enum.dart';
import 'package:bedbug/logic/usecases/feed/get_contents_by_signatures/get_contents_by_signatures.failure.dart';
import 'package:bedbug/logic/usecases/feed/get_contents_by_signatures/get_contents_by_signatures.params.dart';
import 'package:bedbug/logic/usecases/feed/get_contents_by_signatures/get_contents_by_signatures.usecase.dart';
import 'package:bedbug/logic/usecases/signature/get_signature/get_signature.failure.dart';
import 'package:bedbug/logic/usecases/signature/get_signature/get_signature.params.dart';
import 'package:bedbug/logic/usecases/signature/get_signature/get_signature.usecase.dart';
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
        avatarFrames: const ['ʕ•ᴥ•ʔ'],
        socialLinks: const {SocialNetwork.github: 'punaise-royale'},
      ),
    );
  }
}

/// Fake [GetContentsBySignaturesUsecase] retournant un unique contenu de l'auteur demandé.
class _FakeGetContentsBySignaturesUsecase implements GetContentsBySignaturesUsecase {
  @override
  Future<Either<GetContentsBySignaturesFailure, CursorPage<ContentDetailed>>> call(
    GetContentsBySignaturesParams params,
  ) async {
    final content = TextContent(
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
    );
    return Right(
      CursorPage(
        items: [ContentDetailed(content: content, signature: null, reactionCount: 0, isViewed: false)],
        nextCursor: null,
      ),
    );
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
