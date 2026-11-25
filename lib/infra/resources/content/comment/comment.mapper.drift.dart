import 'package:bedbug/infra/resources/content/comment/comment.entity.dart';
import 'package:bedbug/infra/resources/data.exception.dart';
import 'package:bedbug/infra/resources/drift.database.dart';

/// Conversion entre un [Comment] et sa ligne de la table `comments`.
abstract final class CommentDriftMapper {
  /// Reconstruit le commentaire d'une ligne.
  ///
  /// [row] : ligne lue dans la table `comments`.
  static Comment toEntity(CommentRow row) {
    try {
      return Comment(
        id: row.id,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        contentId: row.contentId,
        signatureId: row.signatureId,
        body: row.body,
      );
    } catch (error) {
      throw DataException('CommentDriftMapper', error);
    }
  }

  /// Construit la ligne à écrire pour un commentaire.
  ///
  /// [entity] : commentaire à écrire.
  static CommentsCompanion toCompanion(Comment entity) {
    return CommentsCompanion.insert(
      id: entity.id,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      contentId: entity.contentId,
      signatureId: entity.signatureId,
      body: entity.body,
    );
  }
}
