import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/shared/domain/repository.dart';
import 'package:bedbug/shared/domain/repository_params.dart';

/// Contrat du repository gérant les [Content].
abstract class ContentRepository extends Repository<Content, ContentRepositoryParams> {}

/// Paramètres de requête du [ContentRepository].
class ContentRepositoryParams extends RepositoryParams {
  /// Crée des [ContentRepositoryParams].
  ///
  /// - [authorId] : filtre optionnel sur l'auteur du contenu.
  /// - [page] : numéro de la page demandée. Par défaut 1.
  /// - [limit] : nombre maximum d'éléments à retourner. `null` = tous.
  /// - [orderBy] : tri appliqué aux résultats.
  const ContentRepositoryParams({super.page, super.limit, super.orderBy, this.authorId});

  /// Filtre sur l'identifiant de l'auteur. `null` = aucun filtre.
  final String? authorId;
}
