import 'package:bedbug/infra/resources/content/viewed_content/viewed_content.entity.dart';
import 'package:bedbug/infra/resources/drift.database.dart';

/// Conversion entre un [ViewedContent] et sa ligne de la table `viewed_contents`.
abstract final class ViewedContentDriftMapper {
  /// Construit la ligne à écrire pour une trace d'affichage.
  ///
  /// [entity] : trace à écrire.
  static ViewedContentsCompanion toCompanion(ViewedContent entity) {
    return ViewedContentsCompanion.insert(id: entity.id, createdAt: entity.createdAt, updatedAt: entity.updatedAt);
  }
}
