import 'package:bedbug/application/screens/signature/signature_screen.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/usecases/get_contents_by_authors_usecase.dart';
import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:bedbug/features/signature/domain/enums/social_network.dart';
import 'package:bedbug/features/signature/domain/usecases/get_signature_usecase.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

/// Fake [GetSignatureUsecase] retournant toujours le même profil.
class _FakeGetSignatureUsecase implements GetSignatureUsecase {
  @override
  Future<Either<GetSignatureFailure, Signature>> call(GetSignatureParams params) async {
    return Right(
      Signature(
        id: params.authorId,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        pseudo: 'Punaise-Royale',
        avatarText: 'ʕ•ᴥ•ʔ',
        socialLinks: const {SocialNetwork.github: 'punaise-royale'},
      ),
    );
  }
}

/// Fake [GetContentsByAuthorsUsecase] retournant un unique contenu de l'auteur demandé.
class _FakeGetContentsByAuthorsUsecase implements GetContentsByAuthorsUsecase {
  @override
  Future<Either<GetContentsByAuthorsFailure, List<Content>>> call(GetContentsByAuthorsParams params) async {
    return Right([
      TextContent(
        id: 'post',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        authorId: params.authorIds.first,
        senderId: 'local',
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
        getContentsByAuthorsUsecaseProvider.overrideWithValue(_FakeGetContentsByAuthorsUsecase()),
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
