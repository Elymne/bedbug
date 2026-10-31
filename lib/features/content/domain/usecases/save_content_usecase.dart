import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/drawing_content.dart';
import 'package:bedbug/features/content/domain/repositories/content_repository.dart';
import 'package:bedbug/features/content/domain/repositories/storage_repository.dart';
import 'package:bedbug/features/content/domain/services/content_size_service.dart';
import 'package:bedbug/features/content/domain/services/drawing_validation_service.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_storage_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SaveContentUsecase].
final saveContentUsecaseProvider = Provider<SaveContentUsecase>((ref) {
  return SaveContentUsecase(
    ref.read(contentRepositoryProvider),
    ref.read(storageRepositoryProvider),
    ref.read(drawingValidationServiceProvider),
    ref.read(contentSizeServiceProvider),
  );
});

/// Persiste un contenu dans le stockage local.
///
/// Le poids (`sizeInBytes`) fourni par l'appelant n'est pas fiable : ce use case le fait recalculer par
/// [ContentSizeService] avant persistance, pour que le suivi du stockage reste juste.
class SaveContentUsecase extends Usecase<SaveContentParams, SaveContentFailure, Content> {
  /// Crée un [SaveContentUsecase].
  SaveContentUsecase(
    this._contentRepository,
    this._storageRepository,
    this._drawingValidationService,
    this._contentSizeService,
  );

  final ContentRepository _contentRepository;
  final StorageRepository _storageRepository;
  final DrawingValidationService _drawingValidationService;
  final ContentSizeService _contentSizeService;

  @override
  Future<Either<SaveContentFailure, Content>> call(SaveContentParams params) async {
    try {
      final content = params.content;
      // Un dessin hors limites (trop de couleurs, de points, de traits) n'est jamais enregistré.
      if (content is DrawingContent && !_drawingValidationService.isValid(content.drawing)) {
        return const Left(SaveContentFailure.invalidContent);
      }
      final resized = content.copyWithSizeInBytes(_contentSizeService.sizeInBytes(content));

      final saved = await _contentRepository.addOne(resized);
      await _storageRepository.adjustCurrentSizeInBytes(saved.sizeInBytes);
      return Right(saved);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('SaveContentUsecase', error, stackTrace);
      return const Left(SaveContentFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('SaveContentUsecase', error, stackTrace);
      return const Left(SaveContentFailure.unknown);
    }
  }
}

/// Échecs possibles du [SaveContentUsecase].
enum SaveContentFailure {
  /// Le contenu dépasse ses limites (dessin trop riche, mal formé) : il n'est pas enregistré.
  invalidContent,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la sauvegarde.
  unknown,
}

/// Paramètres du [SaveContentUsecase].
class SaveContentParams extends Params {
  /// Crée des [SaveContentParams].
  ///
  /// - [content] : entité à persister.
  const SaveContentParams({required this.content});

  /// Contenu à persister.
  final Content content;
}
