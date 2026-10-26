import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/shared/domain/entity.dart';

/// Longueur maximale, en caractères, du corps d'un [Comment].
///
/// Plus long qu'une bulle de réaction (un commentaire développe un avis),
/// mais borné : il voyage de pair à pair et doit rester sous ~2 Ko.
const int maxCommentLength = 500;

/// Nombre maximal de commentaires conservés par contenu.
///
/// Comme pour les réactions, rien n'empêche un pair de fabriquer des
/// commentaires en masse : au-delà, les plus anciens sont écartés, ce qui
/// plafonne le poids des commentaires d'un contenu à ~200 Ko.
const int maxCommentsPerContent = 100;

/// Commentaire posté sur un [Content], signé par la signature de son auteur.
///
/// Entité à part du contenu et des réactions : il voyage seul entre pairs.
/// Contrairement à une réaction, une signature peut laisser plusieurs
/// commentaires sur un même contenu.
class Comment extends Entity {
  /// Crée un [Comment].
  ///
  /// - [contentId] : identifiant du contenu commenté.
  /// - [authorId] : identifiant de la signature qui a commenté.
  /// - [body] : corps du commentaire, au plus [maxCommentLength] caractères.
  Comment({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.contentId,
    required this.authorId,
    required this.body,
  });

  /// Identifiant du [Content] auquel ce commentaire est rattaché.
  final String contentId;

  /// Identifiant de la signature qui a commenté.
  final String authorId;

  /// Corps du commentaire.
  final String body;
}
