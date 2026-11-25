import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/infra/resources/content/content/content.entity.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.dart';
import 'package:bedbug/infra/resources/content/content/content.repository.drift.dart';
import 'package:bedbug/infra/resources/content/content/drawing_content.entity.dart';
import 'package:bedbug/infra/resources/content/drawing/drawing.value_object.dart';
import 'package:bedbug/infra/resources/datasource.exception.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.drift.dart';
import 'package:bedbug/logic/usecases/content/save_content/save_content.failure.dart';
import 'package:bedbug/logic/usecases/content/save_content/save_content.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SaveContentUsecase].
final saveContentUsecaseProvider = Provider<SaveContentUsecase>((ref) {
  return SaveContentUsecase(ref.read(contentRepositoryProvider), ref.read(errorLogRepositoryProvider));
});

/// Persiste un contenu dans le stockage local.
///
/// Le poids (`sizeInBytes`) fourni par l'appelant n'est pas fiable : ce use case le fait recalculer par
/// [Content.sizeInBytesOf] avant persistance : le budget des échanges et le choix des
/// contenus à supprimer quand le stockage est plein s'appuient sur ce poids.
class SaveContentUsecase extends Usecase<SaveContentParams, SaveContentFailure, Content> {
  /// Crée un [SaveContentUsecase].
  SaveContentUsecase(this._contentRepository, this._errorLogRepository);

  /// Repository des contenus.
  final ContentRepository _contentRepository;

  /// Journal des erreurs inattendues.
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<SaveContentFailure, Content>> call(SaveContentParams params) async {
    try {
      final content = params.content;
      // Un dessin hors limites (trop de couleurs, de points, de traits) n'est jamais enregistré.
      if (content is DrawingContent && !Drawing.isValid(content.drawing)) {
        return const Left(SaveContentFailure.invalidContent);
      }
      final resized = content.copyWithSizeInBytes(Content.sizeInBytesOf(content));

      final saved = await _contentRepository.addOne(resized);
      return Right(saved);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('SaveContentUsecase', error, stackTrace);
      return const Left(SaveContentFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('SaveContentUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'SaveContentUsecase', error: error, stackTrace: stackTrace);
      return const Left(SaveContentFailure.unknown);
    }
  }
}
