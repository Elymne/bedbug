import 'package:bedbug/features/content/domain/entities/comment.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/infrastructure/hive_type_ids.dart';
import 'package:hive_ce/hive.dart';

part 'comment_hive_model.g.dart';

/// DTO Hive représentant un [Comment] persisté localement.
@HiveType(typeId: HiveTypeIds.comment)
class CommentHiveModel extends HiveObject {
  /// Crée un [CommentHiveModel].
  CommentHiveModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.authorId,
    required this.body,
  });

  /// Crée un [CommentHiveModel] depuis une entité [Comment].
  factory CommentHiveModel.fromEntity(Comment entity) {
    return CommentHiveModel(
      id: entity.id,
      createdAt: entity.createdAt.millisecondsSinceEpoch,
      updatedAt: entity.updatedAt.millisecondsSinceEpoch,
      authorId: entity.authorId,
      body: entity.body,
    );
  }

  /// Identifiant unique du commentaire.
  @HiveField(0)
  final String id;

  /// Date de création en millisecondes depuis l'époque Unix.
  @HiveField(1)
  final int createdAt;

  /// Date de mise à jour en millisecondes depuis l'époque Unix.
  @HiveField(2)
  final int updatedAt;

  /// Identifiant de l'auteur du commentaire.
  @HiveField(3)
  final String authorId;

  /// Corps du commentaire.
  @HiveField(4)
  final String body;

  /// Convertit ce modèle en entité [Comment].
  Comment toEntity() {
    try {
      return Comment(
        id: id,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
        authorId: authorId,
        body: body,
      );
    } catch (error) {
      throw DataException('CommentHiveModel', error);
    }
  }
}
