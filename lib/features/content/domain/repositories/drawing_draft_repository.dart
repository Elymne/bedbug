import 'package:bedbug/features/content/domain/object_values/drawing.dart';

/// Stockage du dessin en cours d'édition, un seul brouillon par appareil.
abstract class DrawingDraftRepository {
  /// Retourne le brouillon enregistré, ou `null` s'il n'y en a pas.
  Future<Drawing?> get();

  /// Enregistre [drawing] à la place du brouillon actuel.
  ///
  /// - [drawing] : dessin en cours d'édition.
  Future<void> save(Drawing drawing);

  /// Efface le brouillon enregistré.
  Future<void> clear();
}
