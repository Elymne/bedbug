import 'package:bedbug/core/domain/entity.dart';
import 'package:bedbug/resources/content/comment/comment.config.dart';
import 'package:bedbug/resources/content/content/content.entity.dart';

/// Commentaire posté sur un [Content], signé par la signature de son auteur.
///
/// Entité à part du contenu et des réactions : il voyage seul entre pairs.
/// Contrairement à une réaction, une signature peut laisser plusieurs
/// commentaires sur un même contenu.
class Comment extends Entity {
  /// Crée un [Comment].
  ///
  /// - [contentId] : identifiant du contenu commenté.
  /// - [signatureId] : identifiant de la signature qui a commenté.
  /// - [body] : corps du commentaire, au plus [maxCommentLength] caractères.
  Comment({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.contentId,
    required this.signatureId,
    required this.body,
  });

  /// Identifiant du [Content] auquel ce commentaire est rattaché.
  final String contentId;

  /// Identifiant de la signature qui a commenté.
  final String signatureId;

  /// Corps du commentaire.
  final String body;

  /// Indique si [body] est un corps de commentaire valide : non vide, au plus [maxCommentLength] caractères.
  ///
  /// La règle vaut partout : à la saisie (formulaire), à l'enregistrement (use case), et à la réception d'un
  /// commentaire d'un pair, qui ne passe par aucun formulaire. Les sauts de ligne sont autorisés. La longueur est
  /// comptée en caractères Unicode (runes) et non en unités UTF-16, pour qu'un emoji ne compte pas double.
  ///
  /// - [body] : texte à vérifier.
  static bool isValidBody(String body) {
    return body.trim().isNotEmpty && body.runes.length <= maxCommentLength;
  }
}
