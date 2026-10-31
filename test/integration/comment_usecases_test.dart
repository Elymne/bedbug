import 'dart:io';
import 'dart:math';

import 'package:bedbug/features/content/domain/entities/comment.dart';
import 'package:bedbug/features/content/domain/usecases/get_content_comments_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/save_comment_usecase.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_comment_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/hive_test_helper.dart';

/// Construit un commentaire de test sur le contenu `content`.
///
/// - [id] : identifiant du commentaire.
/// - [createdAt] : date de création, qui décide des commentaires écartés au-delà du plafond.
/// - [body] : corps du commentaire.
Comment _comment({required String id, required DateTime createdAt, String body = 'Trop bien ce post'}) {
  return Comment(
    id: id,
    createdAt: createdAt,
    updatedAt: createdAt,
    contentId: 'content',
    signatureId: 'alice',
    body: body,
  );
}

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

  test('enregistre le corps sans espaces en bordure et autorise plusieurs commentaires du même auteur', () async {
    final saveUsecase = container.read(saveCommentUsecaseProvider);
    final repository = container.read(commentRepositoryProvider);

    await saveUsecase(
      SaveCommentParams(
        comment: _comment(id: 'a', createdAt: DateTime(2026), body: '  Salut  '),
      ),
    );
    await saveUsecase(
      SaveCommentParams(
        comment: _comment(id: 'b', createdAt: DateTime(2026, 2)),
      ),
    );

    final comments = await repository.getAllByContentId('content');
    expect(comments.length, 2);
    expect(comments.firstWhere((comment) => comment.id == 'a').body, 'Salut');
  });

  test('refuse un corps vide ou trop long', () async {
    final saveUsecase = container.read(saveCommentUsecaseProvider);

    final blank = await saveUsecase(
      SaveCommentParams(
        comment: _comment(id: 'a', createdAt: DateTime(2026), body: '  '),
      ),
    );
    final tooLong = await saveUsecase(
      SaveCommentParams(
        comment: _comment(id: 'b', createdAt: DateTime(2026), body: 'a' * (maxCommentLength + 1)),
      ),
    );

    expect(blank.left, SaveCommentFailure.invalidComment);
    expect(tooLong.left, SaveCommentFailure.invalidComment);
  });

  test('un commentaire reçu deux fois n\'est enregistré qu\'une fois', () async {
    final saveUsecase = container.read(saveCommentUsecaseProvider);
    final repository = container.read(commentRepositoryProvider);

    await saveUsecase(
      SaveCommentParams(
        comment: _comment(id: 'a', createdAt: DateTime(2026)),
      ),
    );
    await saveUsecase(
      SaveCommentParams(
        comment: _comment(id: 'a', createdAt: DateTime(2026), body: 'Autre texte'),
      ),
    );

    final comments = await repository.getAllByContentId('content');
    expect(comments.single.body, 'Trop bien ce post');
  });

  test('ne garde que les commentaires les plus récents au-delà du plafond par contenu', () async {
    final saveUsecase = container.read(saveCommentUsecaseProvider);
    final repository = container.read(commentRepositoryProvider);

    for (var index = 0; index <= maxCommentsPerContent; index++) {
      await saveUsecase(
        SaveCommentParams(
          comment: _comment(
            id: 'comment-$index',
            createdAt: DateTime(2026).add(Duration(minutes: index)),
          ),
        ),
      );
    }

    final comments = await repository.getAllByContentId('content');
    expect(comments.length, maxCommentsPerContent);
    expect(comments.map((comment) => comment.id), isNot(contains('comment-0')));
  });

  test('la lecture retourne tous les commentaires du contenu, mélangés', () async {
    final saveUsecase = container.read(saveCommentUsecaseProvider);
    for (var index = 0; index < 20; index++) {
      await saveUsecase(
        SaveCommentParams(
          comment: _comment(
            id: 'comment-$index',
            createdAt: DateTime(2026).add(Duration(minutes: index)),
          ),
        ),
      );
    }
    final getUsecase = GetContentCommentsUsecase(container.read(commentRepositoryProvider), Random(42));

    final result = await getUsecase(const GetContentCommentsParams(contentId: 'content'));

    final ids = result.right!.map((comment) => comment.id).toList();
    expect(ids.toSet(), {for (var index = 0; index < 20; index++) 'comment-$index'});
    expect(ids, isNot(orderedEquals([for (var index = 0; index < 20; index++) 'comment-$index'])));
  });
}
