import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_priority.dart';
import 'package:bedbug/features/content/domain/repositories/content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/extensions/string_uuid_x.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SeedContentsUsecase].
final seedContentsUsecaseProvider = Provider<SeedContentsUsecase>(
  (ref) => SeedContentsUsecase(ref.read(contentRepositoryProvider)),
);

/// Génère une grande quantité de contenus factices pour les tests.
class SeedContentsUsecase
    extends Usecase<SeedContentsParams, SeedContentsFailure, void> {
  /// Crée un [SeedContentsUsecase].
  SeedContentsUsecase(this._contentRepository);

  final ContentRepository _contentRepository;

  @override
  Future<Either<SeedContentsFailure, void>> call(
    SeedContentsParams params,
  ) async {
    try {
      final now = DateTime.now();
      for (var index = 0; index < params.count; index++) {
        final createdAt = now.subtract(Duration(minutes: index));
        await _contentRepository.addOne(
          TextContent(
            id: UuidX.generate(),
            createdAt: createdAt,
            updatedAt: createdAt,
            authorId: 'seed-author',
            senderId: 'seed-sender',
            priority: ContentPriority.public,
            bounce: 0,
            sizeInBytes: 0,
            title: 'Contenu test #${index + 1}',
            body: 'Corps du contenu factice numéro ${index + 1}.',
          ),
        );
      }
      return const Right(null);
    } catch (error, stackTrace) {
      AppLogger.error('SeedContentsUsecase', error, stackTrace);
      return const Left(SeedContentsFailure.unknown);
    }
  }
}

/// Échecs possibles du [SeedContentsUsecase].
enum SeedContentsFailure {
  /// Erreur inattendue lors de la génération des contenus.
  unknown,
}

/// Paramètres du [SeedContentsUsecase].
class SeedContentsParams extends Params {
  /// Crée des [SeedContentsParams].
  ///
  /// - [count] : nombre de contenus à générer. Par défaut : 100.
  const SeedContentsParams({this.count = 100});

  /// Nombre de contenus factices à générer.
  final int count;
}
