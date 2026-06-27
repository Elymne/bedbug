import 'package:bedbug/features/content/domain/entities/comment.dart';
import 'package:bedbug/shared/domain/repository.dart';
import 'package:bedbug/shared/domain/repository_params.dart';

/// Contrat du repository gérant les [Comment].
abstract class CommentRepository extends Repository<Comment, CommentRepositoryParams> {}

/// Paramètres de requête du [CommentRepository].
class CommentRepositoryParams extends RepositoryParams {
  /// Crée des [CommentRepositoryParams].
  ///
  /// - [authorId] : filtre optionnel sur l'auteur du commentaire.
  /// - [limit] : nombre maximum d'éléments à retourner. `null` = tous.
  /// - [orderBy] : tri appliqué aux résultats.
  const CommentRepositoryParams({super.limit, super.orderBy, this.authorId});

  /// Filtre sur l'identifiant de l'auteur. `null` = aucun filtre.
  final String? authorId;
}
