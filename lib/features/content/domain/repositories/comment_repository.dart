import 'package:bedbug/features/content/domain/entities/comment.dart';

/// Contrat du repository gérant les [Comment].
///
/// Pas de mise à jour : un commentaire n'est pas modifiable une fois posté.
abstract class CommentRepository {
  /// Persiste le commentaire [entity].
  Future<void> addOne(Comment entity);

  /// Retourne tous les commentaires rattachés au contenu [contentId], sans ordre garanti.
  Future<List<Comment>> getAllByContentId(String contentId);

  /// Supprime les commentaires dont l'identifiant fait partie de [ids].
  Future<void> deleteMany(List<String> ids);

  /// Supprime tous les commentaires rattachés au contenu [contentId].
  Future<void> deleteAllByContentId(String contentId);

  /// Supprime tous les commentaires rattachés aux contenus [contentIds], en un seul parcours de la box.
  Future<void> deleteAllByContentIds(Set<String> contentIds);

  /// Supprime l'intégralité des commentaires stockés.
  Future<void> deleteAll();
}
