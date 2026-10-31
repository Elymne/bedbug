import 'package:bedbug/features/content/domain/object_values/drawing.dart';
import 'package:bedbug/features/content/domain/repositories/drawing_draft_repository.dart';
import 'package:bedbug/features/content/domain/services/drawing_validation_service.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_drawing_draft_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [GetDrawingDraftUsecase].
final getDrawingDraftUsecaseProvider = Provider<GetDrawingDraftUsecase>((ref) {
  return GetDrawingDraftUsecase(ref.read(drawingDraftRepositoryProvider), ref.read(drawingValidationServiceProvider));
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
  GetDrawingDraftUsecase(this._drawingDraftRepository, this._drawingValidationService);

  /// Stockage du brouillon.
  final DrawingDraftRepository _drawingDraftRepository;

  /// Service de vérification des limites d'un dessin.
  final DrawingValidationService _drawingValidationService;

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
      return const Left(DrawingDraftFailure.unknown);
    }
  }
}

/// Échecs possibles des use cases de lecture et d'écriture du brouillon de dessin.
enum DrawingDraftFailure {
  /// Le brouillon lu est corrompu.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue.
  unknown,
}
