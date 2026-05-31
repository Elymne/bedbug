import 'package:bedbug/shared/domain/entity.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/repository_params.dart';
import 'package:bedbug/shared/query/page.dart';

/// Contrat générique de base pour tous les repositories de l'application.
///
/// [T] est le type de l'entité gérée par le repository.
/// [P] est le type des paramètres de la requête paginée, doit étendre [Params].
/// En pratique, [P] est toujours une sous-classe de [RepositoryParams] — la
/// contrainte est relâchée ici pour éviter les conflits d'invariance des
/// génériques Dart.
///
/// Les méthodes non pertinentes pour un repository concret doivent lever une
/// [UnimplementedError] avec un message explicatif dans leur implémentation.
abstract class Repository<T, P extends Params> {
  /// Persiste une nouvelle entité [entity].
  ///
  /// Retourne l'entité telle qu'elle a été stockée, avec les champs de
  /// traçabilité ([Entity.createdAt], [Entity.updatedAt]) renseignés par l'infrastructure.
  Future<T> addOne(T entity);

  /// Persiste une liste d'entités [entities] en une seule opération atomique.
  Future<void> addMany(List<T> entities);

  /// Met à jour une entité existante [entity].
  ///
  /// Lève une `DatasourceException` si l'entité n'existe pas dans le stockage.
  /// Retourne l'entité mise à jour rafraîchie par l'infrastructure.
  Future<T> updateOne(T entity);

  /// Met à jour une liste d'entités [entities] en une seule opération atomique.
  ///
  /// Lève une `DatasourceException` dès qu'une entité de la liste est introuvable.
  /// Aucune des mises à jour n'est appliquée si l'une d'elles échoue.
  Future<void> updateMany(List<T> entities);

  /// Retourne l'entité correspondant à l'[id] fourni, ou `null` si
  /// introuvable.
  Future<T?> getUnique(String id);

  /// Retourne toutes les entités de la collection, sans filtre ni pagination.
  Future<List<T>> getAll();

  /// Supprime l'entité correspondant à l'[id] fourni.
  ///
  /// Sans effet si le document n'existe pas (opération idempotente).
  ///
  /// Les repositories qui ne supportent pas la suppression doivent lever une
  /// [UnimplementedError] avec un message indiquant l'alternative à utiliser.
  Future<void> deleteOne(String id);

  /// Supprime les entités correspondant aux [ids] fournis en une seule opération.
  ///
  /// Sans effet pour les identifiants inexistants (opération idempotente).
  Future<void> deleteMany(List<String> ids);

  /// Supprime l'intégralité des entités stockées.
  Future<void> deleteAll();

  /// Retourne une page de résultats selon les [params] fournis.
  ///
  /// Supporte le filtrage, le tri et la pagination. Le [Page.total] indique
  /// le nombre total de documents correspondant aux filtres, toutes pages
  /// confondues.
  Future<Page<T>> getMany(P params);
}
