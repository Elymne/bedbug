import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/shared/domain/repository.dart';
import 'package:bedbug/shared/domain/repository_params.dart';
import 'package:bedbug/shared/query/no_pagination.dart';

/// Contrat du repository gérant les [Content].
abstract class ContentRepository
    extends Repository<Content, ContentRepositoryParams> {
  /// Supprime l'intégralité des contenus stockés localement.
  Future<void> deleteAll();
}

/// Paramètres de requête du [ContentRepository].
class ContentRepositoryParams extends RepositoryParams<NoPagination> {
  /// Crée des [ContentRepositoryParams].
  ///
  /// - [authorId] : filtre optionnel sur l'auteur du contenu.
  const ContentRepositoryParams({
    super.pagination,
    super.orderBy,
    this.authorId,
  });

  /// Filtre sur l'identifiant de l'auteur. `null` = aucun filtre.
  final String? authorId;
}
