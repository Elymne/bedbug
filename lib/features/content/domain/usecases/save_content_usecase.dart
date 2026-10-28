import 'dart:convert';

import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/drawing_content.dart';
import 'package:bedbug/features/content/domain/entities/link_content.dart';
import 'package:bedbug/features/content/domain/entities/media_content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/object_values/drawing.dart';
import 'package:bedbug/features/content/domain/object_values/drawing_operation.dart';
import 'package:bedbug/features/content/domain/repositories/content_repository.dart';
import 'package:bedbug/features/content/domain/repositories/storage_repository.dart';
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
  );
});

/// Persiste un contenu dans le stockage local.
///
/// Le poids (`sizeInBytes`) fourni par l'appelant n'est pas fiable — un
/// contenu reçu d'un pair pourrait mentir sur sa taille pour échapper aux
/// limites de stockage. Ce use case détermine donc lui-même le poids réel
/// avant persistance plutôt que de faire confiance à la valeur du contenu
/// passé en paramètre.
class SaveContentUsecase extends Usecase<SaveContentParams, SaveContentFailure, Content> {
  /// Crée un [SaveContentUsecase].
  SaveContentUsecase(this._contentRepository, this._storageRepository, this._drawingValidationService);

  final ContentRepository _contentRepository;
  final StorageRepository _storageRepository;
  final DrawingValidationService _drawingValidationService;

  @override
  Future<Either<SaveContentFailure, Content>> call(SaveContentParams params) async {
    try {
      final content = params.content;
      // Un dessin hors limites (trop de couleurs, de points, de traits) n'est jamais enregistré.
      if (content is DrawingContent && !_drawingValidationService.isValid(content.drawing)) {
        return const Left(SaveContentFailure.invalidContent);
      }
      final sizeInBytes = await _computeSizeInBytes(content);
      final resized = content.copyWithSizeInBytes(sizeInBytes);

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

  /// Détermine le poids réel de [content], selon son type concret.
  ///
  /// Somme des octets UTF-8 de ses champs texte, calculable directement
  /// depuis les données du domaine. Un [MediaContent] ne stocke que les
  /// adresses de ses médias, jamais les fichiers : son poids est celui de
  /// ces adresses. Un [DrawingContent] pèse son titre et ses opérations.
  Future<int> _computeSizeInBytes(Content content) async {
    if (content is TextContent) {
      return utf8.encode(content.title).length + utf8.encode(content.body).length;
    }

    if (content is LinkContent) {
      final fields = [
        content.title,
        content.url,
        content.body,
        content.ogTitle,
        content.ogDescription,
        content.ogImageUrl,
      ];
      return fields.whereType<String>().fold<int>(0, (total, field) => total + utf8.encode(field).length);
    }

    if (content is MediaContent) {
      final fields = [content.title, content.body, for (final media in content.media) media.url];
      return fields.whereType<String>().fold<int>(0, (total, field) => total + utf8.encode(field).length);
    }

    if (content is DrawingContent) {
      return utf8.encode(content.title).length + _drawingSizeInBytes(content.drawing);
    }

    return content.sizeInBytes;
  }

  /// Retourne le poids maximal de [drawing] une fois stocké.
  ///
  /// Une borne haute plutôt que le poids exact de son encodage, qui dépend
  /// du stockage : 4 octets par couleur, 12 par opération et 4 par point.
  int _drawingSizeInBytes(Drawing drawing) {
    var total = drawing.palette.length * 4;
    for (final operation in drawing.operations) {
      total += 12;
      if (operation is DrawingStroke) {
        total += operation.points.length * 4;
      }
    }
    return total;
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
