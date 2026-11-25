import 'package:bedbug/infra/resources/content/seen_content/seen_content.entity.dart';
import 'package:bedbug/infra/resources/drift.database.dart';

/// Conversion entre un [SeenContent] et sa ligne de la table `seen_contents`.
///
/// Séparée du repository parce que la suppression des contenus écrit aussi ces traces, dans la même transaction.
abstract final class SeenContentDriftMapper {
  /// Construit la ligne à écrire pour une trace.
  ///
  /// [entity] : trace à écrire.
  static SeenContentsCompanion toCompanion(SeenContent entity) {
    return SeenContentsCompanion.insert(id: entity.id, createdAt: entity.createdAt, updatedAt: entity.updatedAt);
  }
}
