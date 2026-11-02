import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/content/drawing/drawing.value_object.dart';
import 'package:bedbug/resources/content/drawing/drawing_draft.repository.dart';
import 'package:bedbug/resources/content/drawing/drawing_draft.repository.hive.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.hive.dart';
import 'package:bedbug/services/content/drawing_validation.service.dart';
import 'package:bedbug/usecases/content/get_drawing_draft/get_drawing_draft.failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetDrawingDraftUsecase].
final getDrawingDraftUsecaseProvider = Provider<GetDrawingDraftUsecase>((ref) {
  return GetDrawingDraftUsecase(
    ref.read(drawingDraftRepositoryProvider),
    ref.read(drawingValidationServiceProvider),
    ref.read(errorLogRepositoryProvider),
  );
});

/// Récupère le dessin laissé en cours, pour le reprendre là où il en était.
///
/// Dessiner prend du temps, et un téléphone interrompt : un appel, un
/// message, une autre app ouverte quelques minutes, et le système peut
/// fermer BedBug en arrière-plan. Le dessin en cours est donc enregistré à
/// chaque trait, et repris à la prochaine ouverture de l'éditeur. Un
/// brouillon qui ne respecte plus les limites d'un dessin (ancienne version
/// de l'app, fichier abîmé) est écarté plutôt que de bloquer l'éditeur.
class GetDrawingDraftUsecase extends Usecase<NoParams, DrawingDraftFailure, Drawing?> {
  /// Crée un [GetDrawingDraftUsecase].
  GetDrawingDraftUsecase(this._drawingDraftRepository, this._drawingValidationService, this._errorLogRepository);

  /// Stockage du brouillon.
  final DrawingDraftRepository _drawingDraftRepository;

  /// Service de vérification des limites d'un dessin.
  final DrawingValidationService _drawingValidationService;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<DrawingDraftFailure, Drawing?>> call(NoParams params) async {
    try {
      final draft = await _drawingDraftRepository.get();
      if (draft == null || !_drawingValidationService.isValid(draft)) {
        return const Right(null);
      }
      return Right(draft);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('GetDrawingDraftUsecase', error, stackTrace);
      return const Left(DrawingDraftFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('GetDrawingDraftUsecase', error, stackTrace);
      return const Left(DrawingDraftFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('GetDrawingDraftUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'GetDrawingDraftUsecase', error: error, stackTrace: stackTrace);
      return const Left(DrawingDraftFailure.unknown);
    }
  }
}
