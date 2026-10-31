import 'package:bedbug/application/screens/home/home_screen.dart';
import 'package:bedbug/application/widgets/content_tile/content_widget.dart';
import 'package:bedbug/application/widgets/fields/content_search_input.dart';
import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/usecases/get_home_feed_usecase.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

/// Fake [GetHomeFeedUsecase] retournant une liste fixe fournie au test.
class _FakeGetHomeFeedUsecase implements GetHomeFeedUsecase {
  _FakeGetHomeFeedUsecase(this._contents);
  final List<Content> _contents;

  @override
  Future<Either<GetHomeFeedFailure, List<Content>>> call(NoParams params) async => Right(_contents);
}

TextContent _buildTextContent(String id) {
  return TextContent(
    id: id,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    signatureId: 'local',
    flair: 'test',
    origin: ContentOrigin.owned,
    broadcastScore: 1,
    survivalScore: 1,
    displayScore: 1,
    bounce: 0,
    sizeInBytes: 10,
    title: 'Titre $id',
    body: 'Corps $id',
  );
}

/// Fake [GetHomeFeedUsecase] dont la liste change en cours de test, comme après la réception de contenus d'un pair.
class _ChangingGetHomeFeedUsecase implements GetHomeFeedUsecase {
  _ChangingGetHomeFeedUsecase(this.contents);

  /// Liste retournée au prochain appel.
  List<Content> contents;

  @override
  Future<Either<GetHomeFeedFailure, List<Content>>> call(NoParams params) async => Right(contents);
}

void main() {
  testWidgets('tirer le fil vers le bas affiche les contenus reçus depuis', (tester) async {
    final usecase = _ChangingGetHomeFeedUsecase([_buildTextContent('1')]);
    await pumpApp(tester, const HomeScreen(), overrides: [getHomeFeedUsecaseProvider.overrideWithValue(usecase)]);
    await tester.pump();
    await tester.pump();
    expect(find.byType(ContentWidget), findsOneWidget);

    usecase.contents = [_buildTextContent('1'), _buildTextContent('2')];
    await tester.fling(find.byType(RefreshIndicator), const Offset(0, 300), 1000);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(RefreshProgressIndicator), findsNothing);

    expect(find.byType(ContentWidget), findsNWidgets(2));
  });

  testWidgets('un accueil vide se recharge aussi, pour faire apparaître les premiers contenus', (tester) async {
    final usecase = _ChangingGetHomeFeedUsecase([]);
    await pumpApp(tester, const HomeScreen(), overrides: [getHomeFeedUsecaseProvider.overrideWithValue(usecase)]);
    await tester.pump();
    await tester.pump();
    expect(find.byType(ContentWidget), findsNothing);

    usecase.contents = [_buildTextContent('1')];
    await tester.fling(find.byType(RefreshIndicator), const Offset(0, 300), 1000);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(RefreshProgressIndicator), findsNothing);

    expect(find.byType(ContentWidget), findsOneWidget);
  });

  testWidgets('affiche la barre de recherche et le message vide quand aucun contenu', (tester) async {
    await pumpApp(
      tester,
      const HomeScreen(),
      overrides: [getHomeFeedUsecaseProvider.overrideWithValue(_FakeGetHomeFeedUsecase(const []))],
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
        getHomeFeedUsecaseProvider.overrideWithValue(
          _FakeGetHomeFeedUsecase([_buildTextContent('1'), _buildTextContent('2')]),
        ),
      ],
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(ContentWidget), findsNWidgets(2));
  });
}
