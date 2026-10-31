import 'package:bedbug/features/content/domain/object_values/drawing.dart';
import 'package:bedbug/features/content/domain/usecases/get_drawing_draft_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/save_drawing_draft_usecase.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [DrawingDraftNotifier].
final drawingDraftNotifierProvider = AsyncNotifierProvider<DrawingDraftNotifier, Drawing?>(DrawingDraftNotifier.new);

/// Notifier portant le brouillon du dessin en cours, `null` s'il n'y en a pas.
///
/// Partagé par la page de création, qui reprend le brouillon à l'ouverture
/// de l'éditeur, et par l'éditeur, qui l'enregistre à chaque modification.
class DrawingDraftNotifier extends AsyncNotifier<Drawing?> {
  /// Cas d'usage de lecture du brouillon.
  late final _getDrawingDraftUsecase = ref.read(getDrawingDraftUsecaseProvider);

  /// Cas d'usage d'enregistrement du brouillon.
  late final _saveDrawingDraftUsecase = ref.read(saveDrawingDraftUsecaseProvider);

  @override
  Future<Drawing?> build() async {
    final result = await _getDrawingDraftUsecase(const NoParams());
    // Un brouillon illisible est perdu : mieux vaut repartir d'un dessin vide que bloquer l'éditeur.
    return result.right;
  }

  /// Enregistre [drawing] comme brouillon.
  ///
  /// Un échec n'interrompt pas le dessin : au pire, le brouillon garde la
  /// version précédente.
  ///
  /// - [drawing] : dessin en cours d'édition.
  Future<void> save(Drawing drawing) async {
    state = AsyncData(drawing);
    await _saveDrawingDraftUsecase(SaveDrawingDraftParams(drawing: drawing));
  }

  /// Efface le brouillon, une fois le dessin validé ou abandonné.
  Future<void> clear() async {
    state = const AsyncData(null);
    await _saveDrawingDraftUsecase(const SaveDrawingDraftParams(drawing: null));
  }
}
