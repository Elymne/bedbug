import 'dart:io';

import 'package:bedbug/features/content/domain/entities/reaction.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/repositories/storage_repository.dart';
import 'package:bedbug/features/content/domain/usecases/enforce_storage_limit_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/get_storage_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/save_storage_limit_usecase.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_reaction_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_seen_content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_storage_repository.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/hive_test_helper.dart';

/// Poids de chaque contenu de test : deux contenus remplissent 1 Mo.
const int _contentSize = bytesPerMegabyte ~/ 2;

/// Construit un [TextContent] de [_contentSize] octets.
///
/// - [id] : identifiant du contenu.
/// - [survivalScore] : priorité de conservation.
/// - [origin] : provenance, reçu par défaut.
/// - [createdAt] : date de création, fixe par défaut.
TextContent _buildContent(
  String id, {
  required double survivalScore,
  ContentOrigin origin = ContentOrigin.public,
  DateTime? createdAt,
}) {
  final date = createdAt ?? DateTime(2026, 10);
  return TextContent(
    id: id,
    createdAt: date,
    updatedAt: date,
    signatureId: 'author',
    flair: 'test',
    origin: origin,
    broadcastScore: 0,
    survivalScore: survivalScore,
    displayScore: 0,
    bounce: 0,
    sizeInBytes: _contentSize,
    title: 'Titre $id',
    body: 'Corps $id',
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

  /// Enregistre [contents] et règle la limite à [megabytes] Mo.
  Future<void> arrange(List<TextContent> contents, {required int megabytes}) async {
    await container.read(contentRepositoryProvider).addMany(contents);
    await container.read(saveStorageLimitUsecaseProvider)(
      SaveStorageLimitParams(maxSizeInBytes: megabytes * bytesPerMegabyte),
    );
  }

  /// Identifiants des contenus encore présents.
  Future<Set<String>> remainingIds() async {
    final contents = await container.read(contentRepositoryProvider).getAll();
    return contents.map((content) => content.id).toSet();
  }

  group('EnforceStorageLimitUsecase', () {
    test('ne supprime rien sous la limite', () async {
      await arrange([_buildContent('a', survivalScore: 0.1), _buildContent('b', survivalScore: 0.2)], megabytes: 1);

      final result = await container.read(enforceStorageLimitUsecaseProvider)(const NoParams());

      expect(result.right, 0);
      expect(await remainingIds(), {'a', 'b'});
    });

    test('supprime les plus faibles survivalScore, juste assez pour repasser sous la limite', () async {
      await arrange([
        _buildContent('fort', survivalScore: 0.9),
        _buildContent('faible', survivalScore: 0.1),
        _buildContent('moyen', survivalScore: 0.5),
        _buildContent('moins-faible', survivalScore: 0.2),
      ], megabytes: 1);

      final result = await container.read(enforceStorageLimitUsecaseProvider)(const NoParams());

      expect(result.right, 2);
      expect(await remainingIds(), {'fort', 'moyen'});
    });

    test('supprime le plus ancien à score égal', () async {
      await arrange([
        _buildContent('recent', survivalScore: 0.5, createdAt: DateTime(2026, 10, 3)),
        _buildContent('ancien', survivalScore: 0.5, createdAt: DateTime(2026, 10, 1)),
        _buildContent('milieu', survivalScore: 0.5, createdAt: DateTime(2026, 10, 2)),
      ], megabytes: 1);

      await container.read(enforceStorageLimitUsecaseProvider)(const NoParams());

      expect(await remainingIds(), {'recent', 'milieu'});
    });

    test('ne supprime jamais les contenus de l\'utilisateur, même au-delà de la limite', () async {
      await arrange([
        _buildContent('mien-1', survivalScore: 0, origin: ContentOrigin.owned),
        _buildContent('mien-2', survivalScore: 0, origin: ContentOrigin.owned),
        _buildContent('mien-3', survivalScore: 0, origin: ContentOrigin.owned),
        _buildContent('recu', survivalScore: 1),
      ], megabytes: 1);

      final result = await container.read(enforceStorageLimitUsecaseProvider)(const NoParams());

      expect(result.right, 1);
      expect(await remainingIds(), {'mien-1', 'mien-2', 'mien-3'});
    });

    test('mémorise les contenus supprimés, retire leurs réactions et corrige le compteur', () async {
      await arrange([
        _buildContent('garde-1', survivalScore: 0.9),
        _buildContent('garde-2', survivalScore: 0.8),
        _buildContent('supprime', survivalScore: 0.1),
      ], megabytes: 1);
      final now = DateTime.now();
      await container
          .read(reactionRepositoryProvider)
          .addOne(
            Reaction(
              id: 'reaction',
              createdAt: now,
              updatedAt: now,
              contentId: 'supprime',
              authorId: 'auteur',
              avatarText: ':)',
              bubbleText: 'ok',
            ),
          );

      await container.read(enforceStorageLimitUsecaseProvider)(const NoParams());

      final seen = await container.read(seenContentRepositoryProvider).getSeenAmong({'supprime', 'garde-1'});
      final reactions = await container.read(reactionRepositoryProvider).getAllByContentId('supprime');
      final storage = (await container.read(getStorageUsecaseProvider)(const NoParams())).right;
      expect(seen, {'supprime'});
      expect(reactions, isEmpty);
      expect(storage?.currentSizeInBytes, 2 * _contentSize);
    });
  });

  group('SaveStorageLimitUsecase', () {
    test('conserve le poids actuel', () async {
      await container.read(storageRepositoryProvider).adjustCurrentSizeInBytes(42);

      final result = await container.read(saveStorageLimitUsecaseProvider)(
        const SaveStorageLimitParams(maxSizeInBytes: 50 * bytesPerMegabyte),
      );

      expect(result.right?.maxSizeInBytes, 50 * bytesPerMegabyte);
      expect(result.right?.currentSizeInBytes, 42);
    });

    test('refuse une limite hors des bornes', () async {
      final usecase = container.read(saveStorageLimitUsecaseProvider);

      final tooLow = await usecase(const SaveStorageLimitParams(maxSizeInBytes: bytesPerMegabyte - 1));
      final tooHigh = await usecase(
        const SaveStorageLimitParams(maxSizeInBytes: (maxStorageLimitInMegabytes + 1) * bytesPerMegabyte),
      );

      expect(tooLow.isSuccess, isFalse);
      expect(tooHigh.isSuccess, isFalse);
    });
  });
}
