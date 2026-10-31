import 'package:bedbug/features/content/domain/object_values/drawing.dart';
import 'package:bedbug/features/content/domain/repositories/drawing_draft_repository.dart';
import 'package:bedbug/features/content/domain/usecases/get_drawing_draft_usecase.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_drawing_draft_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SaveDrawingDraftUsecase].
final saveDrawingDraftUsecaseProvider = Provider<SaveDrawingDraftUsecase>((ref) {
  return SaveDrawingDraftUsecase(ref.read(drawingDraftRepositoryProvider));
});

/// Enregistre le dessin en cours comme brouillon, ou efface le brouillon une fois le dessin terminé ou abandonné.
///
/// Appelé à chaque modification du dessin : si le système ferme l'app
/// pendant que l'utilisateur est ailleurs, il retrouve son dessin au dernier
/// trait près. Le brouillon est effacé dès que le dessin est validé ou que
/// l'éditeur est fermé volontairement, pour ne pas ressortir un dessin
/// abandonné à la prochaine ouverture.
class SaveDrawingDraftUsecase extends Usecase<SaveDrawingDraftParams, DrawingDraftFailure, void> {
  /// Crée un [SaveDrawingDraftUsecase].
  SaveDrawingDraftUsecase(this._drawingDraftRepository);

  /// Stockage du brouillon.
  final DrawingDraftRepository _drawingDraftRepository;

  @override
  Future<Either<DrawingDraftFailure, void>> call(SaveDrawingDraftParams params) async {
    try {
      final drawing = params.drawing;
      if (drawing == null) {
        await _drawingDraftRepository.clear();
        return const Right(null);
      }
      await _drawingDraftRepository.save(drawing);
      return const Right(null);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('SaveDrawingDraftUsecase', error, stackTrace);
      return const Left(DrawingDraftFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('SaveDrawingDraftUsecase', error, stackTrace);
      return const Left(DrawingDraftFailure.unknown);
    }
  }
}

/// Paramètres du [SaveDrawingDraftUsecase].
class SaveDrawingDraftParams extends Params {
  /// Crée des [SaveDrawingDraftParams].
  ///
  /// - [drawing] : dessin en cours à enregistrer, `null` pour effacer le brouillon.
  const SaveDrawingDraftParams({required this.drawing});

  /// Dessin en cours à enregistrer, `null` pour effacer le brouillon.
  final Drawing? drawing;
}
