import 'package:bedbug/features/content/domain/object_values/drawing.dart';
import 'package:bedbug/features/content/domain/object_values/drawing_point.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [DrawingLiveStrokeNotifier].
final drawingLiveStrokeNotifierProvider = NotifierProvider.autoDispose<DrawingLiveStrokeNotifier, DrawingLiveStroke?>(
  DrawingLiveStrokeNotifier.new,
);

/// Notifier portant le trait en cours de tracé, avant qu'il rejoigne le dessin.
///
/// Mis à jour à chaque mouvement du doigt : séparé du dessin, il ne
/// reconstruit que la surface qui montre le trait en cours. Une fois le
/// trait ajouté au dessin, il reste affiché jusqu'à ce que l'image du dessin
/// le contienne ([DrawingLiveStroke.committedRevision]), pour ne pas
/// clignoter entre les deux.
class DrawingLiveStrokeNotifier extends Notifier<DrawingLiveStroke?> {
  @override
  DrawingLiveStroke? build() {
    return null;
  }

  /// Commence un trait au point [point], tracé par le doigt [pointer].
  ///
  /// - [pointer] : identifiant du doigt qui trace.
  /// - [point] : premier point du trait.
  /// - [seed] : graine du trait, gardée jusqu'à son ajout pour que l'aperçu soit identique au résultat.
  void start(int pointer, DrawingPoint point, int seed) {
    state = DrawingLiveStroke(pointer: pointer, points: [point], seed: seed);
  }

  /// Prolonge le trait du doigt [pointer] jusqu'à [point].
  ///
  /// Un autre doigt, un point identique au précédent, ou un trait déjà
  /// plein ([maxDrawingStrokePoints]) sont ignorés.
  ///
  /// - [pointer] : identifiant du doigt qui trace.
  /// - [point] : nouveau point.
  void extend(int pointer, DrawingPoint point) {
    final current = state;
    if (current == null || current.pointer != pointer || current.committedRevision != null) {
      return;
    }
    if (current.points.last == point || current.points.length >= maxDrawingStrokePoints) {
      return;
    }
    state = current.copyWith(points: [...current.points, point]);
  }

  /// Marque le trait comme ajouté au dessin, à la révision [revision].
  ///
  /// - [revision] : révision du dessin qui contient le trait.
  void commit(int revision) {
    final current = state;
    if (current == null) {
      return;
    }
    state = current.copyWith(committedRevision: revision);
  }

  /// Abandonne le trait en cours.
  void cancel() {
    state = null;
  }
}

/// Trait en cours de tracé.
class DrawingLiveStroke {
  /// Crée un [DrawingLiveStroke].
  ///
  /// - [pointer] : identifiant du doigt qui trace.
  /// - [points] : points tracés, dans l'ordre.
  /// - [seed] : graine du trait.
  /// - [committedRevision] : révision du dessin qui contient le trait, `null` tant qu'il est en cours.
  const DrawingLiveStroke({required this.pointer, required this.points, required this.seed, this.committedRevision});

  /// Identifiant du doigt qui trace.
  final int pointer;

  /// Points tracés, dans l'ordre.
  final List<DrawingPoint> points;

  /// Graine du trait.
  final int seed;

  /// Révision du dessin qui contient le trait, `null` tant qu'il est en cours.
  final int? committedRevision;

  /// Retourne une copie de ce trait avec les champs fournis modifiés.
  DrawingLiveStroke copyWith({List<DrawingPoint>? points, int? committedRevision}) {
    return DrawingLiveStroke(
      pointer: pointer,
      points: points ?? this.points,
      seed: seed,
      committedRevision: committedRevision ?? this.committedRevision,
    );
  }
}
