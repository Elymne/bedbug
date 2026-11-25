import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.drift.dart';
import 'package:bedbug/infra/resources/content/content/content_origin.enum.dart';
import 'package:bedbug/infra/resources/content/content/text_content.entity.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.entity.dart';
import 'package:bedbug/infra/resources/content/reaction/reaction.repository.drift.dart';
import 'package:bedbug/infra/resources/content/seen_content/seen_content.repository.drift.dart';
import 'package:bedbug/infra/resources/content/storage/cleanup_strategy.enum.dart';
import 'package:bedbug/infra/resources/content/storage/storage.config.dart';
import 'package:bedbug/infra/resources/content/storage/storage.repository.drift.dart';
import 'package:bedbug/infra/resources/content/storage/storage.value_object.dart';
import 'package:bedbug/logic/usecases/storage/enforce_storage_limit/enforce_storage_limit.usecase.dart';
import 'package:bedbug/logic/usecases/storage/save_storage_limit/save_storage_limit.params.dart';
import 'package:bedbug/logic/usecases/storage/save_storage_limit/save_storage_limit.usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/drift_test_helper.dart';

/// Poids réel de chaque contenu de test : deux tiennent sous 1 Mo avec le reste de la base, trois le dépassent.
const int _contentSize = 400 * 1024;

/// Construit un [TextContent] de [_contentSize] octets, réellement écrits dans son corps : la limite porte sur le
/// poids réel de la base.
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
    body: 'x' * _contentSize,
  );
}

void main() {
  late ProviderContainer container;

  setUp(() async {
    container = createTestContainer();
  });

  tearDown(() async {
    container.dispose();
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

    test('mémorise les contenus supprimés, retire leurs réactions et repasse sous la limite réelle', () async {
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
              avatarFrames: const [':)'],
              bubbleText: 'ok',
            ),
          );

      await container.read(enforceStorageLimitUsecaseProvider)(const NoParams());

      final seen = await container.read(seenContentRepositoryProvider).getSeenAmong({'supprime', 'garde-1'});
      final reactions = await container.read(reactionRepositoryProvider).getAllByContentId('supprime');
      final usedBytes = await container.read(storageRepositoryProvider).getUsedSizeInBytes();
      expect(seen, {'supprime'});
      expect(reactions, isEmpty);
      expect(usedBytes, lessThanOrEqualTo(bytesPerMegabyte));
    });
  });

  group('SaveStorageLimitUsecase', () {
    test('conserve la stratégie de nettoyage', () async {
      await container
          .read(storageRepositoryProvider)
          .save(const Storage(maxSizeInBytes: bytesPerMegabyte, strategy: CleanupStrategy.byDate));

      final result = await container.read(saveStorageLimitUsecaseProvider)(
        const SaveStorageLimitParams(maxSizeInBytes: 50 * bytesPerMegabyte),
      );

      expect(result.right?.maxSizeInBytes, 50 * bytesPerMegabyte);
      expect(result.right?.strategy, CleanupStrategy.byDate);
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
