import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/resources/content/drawing/drawing.value_object.dart';
import 'package:bedbug/usecases/content/save_drawing_draft/save_drawing_draft.usecase.dart';

/// Paramètres du [SaveDrawingDraftUsecase].
class SaveDrawingDraftParams extends Params {
  /// Crée des [SaveDrawingDraftParams].
  ///
  /// - [drawing] : dessin en cours à enregistrer, `null` pour effacer le brouillon.
  const SaveDrawingDraftParams({required this.drawing});

  /// Dessin en cours à enregistrer, `null` pour effacer le brouillon.
  final Drawing? drawing;
}
