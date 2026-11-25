import 'package:bedbug/infra/resources/content/comment/comment.entity.dart';

/// Contrat du repository gérant les [Comment].
///
/// Pas de mise à jour : un commentaire n'est pas modifiable une fois posté. Un commentaire n'existe que sur un contenu
/// présent, et disparaît avec lui.
abstract class CommentRepository {
  /// Persiste le commentaire [entity] puis ne garde, sur son contenu, que les [maxPerContent] commentaires les plus
  /// récents (`createdAt`), en une seule opération atomique. Retourne le commentaire stocké.
  ///
  /// Un commentaire de même identifiant déjà présent sur ce contenu est retourné tel quel, sans rien écrire : un
  /// commentaire reçu plusieurs fois n'est enregistré qu'une fois. Le nouveau commentaire peut lui-même être écarté
  /// s'il est plus ancien que tous les autres.
  ///
  /// - [entity] : commentaire à enregistrer.
  /// - [maxPerContent] : nombre maximal de commentaires gardés sur son contenu.
  Future<Comment> addOneKeepingLatest(Comment entity, {required int maxPerContent});

  /// Retourne tous les commentaires rattachés au contenu [contentId], sans ordre garanti.
  Future<List<Comment>> getAllByContentId(String contentId);
}
