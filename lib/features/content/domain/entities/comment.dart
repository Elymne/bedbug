import 'package:bedbug/shared/domain/entity.dart';

/// Commentaire posté par un utilisateur.
class Comment extends Entity {
  /// Crée un [Comment].
  ///
  /// - [authorId] : identifiant de l'auteur du commentaire.
  /// - [body] : corps du commentaire.
  Comment({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.authorId,
    required this.body,
  });

  /// Identifiant de l'auteur du commentaire.
  final String authorId;

  /// Corps du commentaire.
  final String body;
}
