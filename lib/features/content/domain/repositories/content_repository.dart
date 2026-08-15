import 'package:bedbug/features/content/domain/entities/content.dart';

/// Contrat du repository gérant les [Content].
abstract class ContentRepository {
  /// Persiste un nouveau contenu [entity].
  Future<Content> addOne(Content entity);

  /// Persiste une liste de contenus [entities] en une seule opération atomique.
  Future<void> addMany(List<Content> entities);

  /// Met à jour une liste de contenus existants [entities] en une seule opération atomique.
  ///
  /// Lève une `DatasourceException` dès qu'un contenu de la liste est introuvable.
  Future<void> updateMany(List<Content> entities);

  /// Retourne tous les contenus, sans filtre ni limite.
  Future<List<Content>> getAll();

  /// Supprime l'intégralité des contenus stockés.
  Future<void> deleteAll();

  /// Retourne tous les contenus triés par `displayScore` décroissant.
  Future<List<Content>> getAllOrderedByDisplayScoreDesc();
}
