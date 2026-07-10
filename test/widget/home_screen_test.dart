import 'package:bedbug/application/screens/home/home_screen.dart';
import 'package:bedbug/application/widgets/content_tile/content_widget.dart';
import 'package:bedbug/application/widgets/fields/content_search_input.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_priority.dart';
import 'package:bedbug/features/content/domain/usecases/get_contents_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/seed_contents_usecase.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

/// Fake [GetContentsUsecase] retournant une liste fixe fournie au test.
class _FakeGetContentsUsecase implements GetContentsUsecase {
  _FakeGetContentsUsecase(this._contents);
  final List<Content> _contents;

  @override
  Future<Either<GetContentsFailure, List<Content>>> call(GetContentsParams params) async => Right(_contents);
}

/// Fake [SeedContentsUsecase] ne touchant à aucune infrastructure réelle.
class _FakeSeedContentsUsecase implements SeedContentsUsecase {
  @override
  Future<Either<SeedContentsFailure, void>> call(SeedContentsParams params) async => const Right(null);
}

TextContent _buildTextContent(String id) {
  return TextContent(
    id: id,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    authorId: 'local',
    senderId: 'local',
    priority: ContentPriority.owned,
    bounce: 0,
    sizeInBytes: 10,
    title: 'Titre $id',
    body: 'Corps $id',
  );
}

void main() {
  testWidgets('affiche la barre de recherche et le message vide quand aucun contenu', (tester) async {
    await pumpApp(
      tester,
      const HomeScreen(),
      overrides: [
        getContentsUsecaseProvider.overrideWithValue(_FakeGetContentsUsecase(const [])),
        seedContentsUsecaseProvider.overrideWithValue(_FakeSeedContentsUsecase()),
      ],
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(ContentSearchInput), findsOneWidget);
    expect(find.byType(ContentWidget), findsNothing);
  });

  testWidgets('affiche un ContentWidget par contenu retourné', (tester) async {
    await pumpApp(
      tester,
      const HomeScreen(),
      overrides: [
        getContentsUsecaseProvider.overrideWithValue(
          _FakeGetContentsUsecase([_buildTextContent('1'), _buildTextContent('2')]),
        ),
        seedContentsUsecaseProvider.overrideWithValue(_FakeSeedContentsUsecase()),
      ],
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(ContentWidget), findsNWidgets(2));
  });
}
