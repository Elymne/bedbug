import 'package:bedbug/infra/resources/drift.database.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/drift_test_helper.dart';

/// Insère un contenu texte minimal.
///
/// [database] : base de test.
/// [id] : identifiant du contenu.
Future<void> _insertContent(AppDatabase database, String id) async {
  await database
      .into(database.contents)
      .insert(
        ContentsCompanion.insert(
          id: id,
          createdAt: DateTime(2026, 1, 1, 12, 0, 0, 123),
          updatedAt: DateTime(2026, 1, 1, 12, 0, 0, 123),
          storedAt: DateTime(2026, 1, 1, 12, 0, 0, 123),
          signatureId: 'local',
          type: 0,
          origin: 0,
          bounce: 0,
          title: const Value('Titre'),
          searchTitle: 'titre',
          body: Value('Corps ' * 200),
          flair: 'test',
          sizeInBytes: 1200,
          broadcastScore: 1,
          survivalScore: 1,
          displayScore: 1,
          tagValues: const [],
          mediaUrls: const [],
          mediaKinds: const [],
        ),
      );
}

void main() {
  late ProviderContainer container;
  late AppDatabase database;

  setUp(() {
    container = createTestContainer();
    database = container.read(appDatabaseProvider);
  });

  tearDown(() {
    container.dispose();
  });

  test('les dates gardent leurs millisecondes', () async {
    await _insertContent(database, 'content-1');

    final row = await database.select(database.contents).getSingle();

    expect(row.createdAt, DateTime(2026, 1, 1, 12, 0, 0, 123));
  });

  test('supprimer un contenu supprime ses réactions et sa trace d\'affichage, pas sa trace de réception', () async {
    await _insertContent(database, 'content-1');
    await database
        .into(database.reactions)
        .insert(
          ReactionsCompanion.insert(
            id: 'reaction-1',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
            contentId: 'content-1',
            authorId: 'local',
            avatarFrames: const ['🐞'],
            ghostSpeed: 1,
            avatarFrameSpeed: 1,
            bubbleFont: 0,
          ),
        );
    await database
        .into(database.viewedContents)
        .insert(ViewedContentsCompanion.insert(id: 'content-1', createdAt: DateTime(2026), updatedAt: DateTime(2026)));
    await database
        .into(database.seenContents)
        .insert(SeenContentsCompanion.insert(id: 'content-1', createdAt: DateTime(2026), updatedAt: DateTime(2026)));

    await (database.delete(database.contents)..where((table) => table.id.equals('content-1'))).go();

    expect(await database.select(database.reactions).get(), isEmpty);
    expect(await database.select(database.viewedContents).get(), isEmpty);
    expect(await database.select(database.seenContents).get(), hasLength(1));
  });

  test('une réaction sans contenu est refusée', () async {
    final insert = database
        .into(database.reactions)
        .insert(
          ReactionsCompanion.insert(
            id: 'reaction-1',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
            contentId: 'missing',
            authorId: 'local',
            avatarFrames: const ['🐞'],
            ghostSpeed: 1,
            avatarFrameSpeed: 1,
            bubbleFont: 0,
          ),
        );

    await expectLater(insert, throwsA(isA<Exception>()));
  });

  test('le poids utilisé grandit avec les données et rebaisse après suppression', () async {
    final emptySize = await database.usedSizeInBytes();
    for (var index = 0; index < 200; index++) {
      await _insertContent(database, 'content-$index');
    }
    final filledSize = await database.usedSizeInBytes();

    await database.delete(database.contents).go();
    await database.releaseFreePages();
    final releasedSize = await database.usedSizeInBytes();

    expect(filledSize, greaterThan(emptySize));
    expect(releasedSize, lessThan(filledSize));
  });
}
