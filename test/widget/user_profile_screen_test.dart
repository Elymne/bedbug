import 'package:bedbug/application/screens/user_profile/user_profile_screen.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/usecases/get_contents_by_author_usecase.dart';
import 'package:bedbug/features/user/domain/entities/user.dart';
import 'package:bedbug/features/user/domain/enums/social_network.dart';
import 'package:bedbug/features/user/domain/usecases/get_author_usecase.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

/// Fake [GetAuthorUsecase] retournant toujours le même profil.
class _FakeGetAuthorUsecase implements GetAuthorUsecase {
  @override
  Future<Either<GetAuthorFailure, User>> call(GetAuthorParams params) async {
    return Right(
      User(
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

/// Fake [GetContentsByAuthorUsecase] retournant un unique contenu de l'auteur demandé.
class _FakeGetContentsByAuthorUsecase implements GetContentsByAuthorUsecase {
  @override
  Future<Either<GetContentsByAuthorFailure, List<Content>>> call(GetContentsByAuthorParams params) async {
    return Right([
      TextContent(
        id: 'post',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        authorId: params.authorId,
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
  testWidgets('affiche le profil en tête, puis ses posts, et un onglet commentaires en attente', (tester) async {
    await pumpApp(
      tester,
      const UserProfileScreen(userId: 'seed-user-0'),
      overrides: [
        getAuthorUsecaseProvider.overrideWithValue(_FakeGetAuthorUsecase()),
        getContentsByAuthorUsecaseProvider.overrideWithValue(_FakeGetContentsByAuthorUsecase()),
      ],
    );
    // L'icône s'anime en boucle : on avance le temps au lieu d'attendre une
    // stabilisation qui n'arrivera jamais.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('u/Punaise-Royale'), findsOneWidget);
    expect(find.text('GitHub'), findsOneWidget);
    expect(find.text('Mon premier post'), findsOneWidget);

    await tester.tap(find.text('Commentaires'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Les commentaires arrivent bientôt.'), findsOneWidget);
  });
}
