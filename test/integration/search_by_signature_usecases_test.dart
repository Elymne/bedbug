import 'dart:io';

import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/usecases/get_contents_by_signatures_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/save_content_usecase.dart';
import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:bedbug/features/signature/domain/usecases/get_signature_suggestions_usecase.dart';
import 'package:bedbug/features/signature/infrastructure/datasources/hive_signature_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/hive_test_helper.dart';

void main() {
  late Directory tempDir;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await openTestHive();
    container = ProviderContainer();
    // Deux signatures distinctes portant le même nom, et une troisième.
    await container.read(signatureRepositoryProvider).saveMany([
      _buildSignature('bedbug-a', 'Bedbug'),
      _buildSignature('bedbug-b', 'bedbug'),
      _buildSignature('autre', 'Bedside'),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await closeTestHive(tempDir);
  });

  group('suggestions de signatures', () {
    test('propose chaque signature séparément, même si plusieurs portent le même pseudo', () async {
      final result = await container.read(getSignatureSuggestionsUsecaseProvider)(
        const GetSignatureSuggestionsParams(input: 's/bed'),
      );

      expect(result.right!.map((signature) => signature.id), unorderedEquals(['bedbug-a', 'bedbug-b', 'autre']));
    });

    test('ne propose jamais la signature anonyme, même en tapant son pseudo', () async {
      final result = await container.read(getSignatureSuggestionsUsecaseProvider)(
        const GetSignatureSuggestionsParams(input: 'anon'),
      );

      expect(result.right, isEmpty);
    });
  });

  test("les contenus d'une signature excluent ceux de ses homonymes et les anonymes", () async {
    final saveUsecase = container.read(saveContentUsecaseProvider);
    await saveUsecase(SaveContentParams(content: _buildTextContent('a', 'bedbug-a')));
    await saveUsecase(SaveContentParams(content: _buildTextContent('b', 'bedbug-b')));
    await saveUsecase(SaveContentParams(content: _buildTextContent('anonyme', anonymousSignatureId)));

    final result = await container.read(getContentsBySignaturesUsecaseProvider)(
      const GetContentsBySignaturesParams(signatureIds: ['bedbug-a']),
    );

    expect(result.right!.map((content) => content.id), ['a']);
  });

  test('aucun auteur donné : aucun contenu', () async {
    final result = await container.read(getContentsBySignaturesUsecaseProvider)(
      const GetContentsBySignaturesParams(signatureIds: []),
    );

    expect(result.right, isEmpty);
  });
}

Signature _buildSignature(String id, String pseudo) {
  return Signature(id: id, createdAt: DateTime(2026), updatedAt: DateTime(2026), pseudo: pseudo);
}

TextContent _buildTextContent(String id, String signatureId) {
  return TextContent(
    id: id,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    signatureId: signatureId,
    flair: 'test',
    origin: ContentOrigin.public,
    broadcastScore: 1,
    survivalScore: 1,
    displayScore: 1,
    bounce: 0,
    sizeInBytes: 10,
    title: 'Titre $id',
    body: 'Corps $id',
  );
}
