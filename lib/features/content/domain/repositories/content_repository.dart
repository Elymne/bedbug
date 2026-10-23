import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/object_values/flair_suggestion.dart';

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

  /// Retourne tous les contenus dont le titre ou le flair contient [query], insensible à la casse.
  Future<List<Content>> getAllMatchingTitleOrFlair(String query);

  /// Retourne tous les contenus rattachés exactement au flair [flair] (déjà normalisé).
  Future<List<Content>> getAllByFlair(String flair);

  /// Retourne tous les contenus dont l'auteur fait partie de [authorIds].
  Future<List<Content>> getAllByAuthors(Set<String> authorIds);

  /// Retourne tous les contenus de provenance [origin].
  Future<List<Content>> getAllByOrigin(ContentOrigin origin);

  /// Retourne le contenu d'identifiant [id], ou `null` s'il n'existe pas.
  Future<Content?> getById(String id);

  /// Supprime le contenu d'identifiant [id]. Sans effet s'il n'existe pas.
  Future<void> deleteOne(String id);

  /// Retourne les flairs commençant par [prefix] (déjà normalisé), avec leur nombre de contenus.
  ///
  /// Les flairs sont triés du plus utilisé au moins utilisé, puis par ordre
  /// alphabétique à égalité, et limités aux [limit] premiers.
  Future<List<FlairSuggestion>> getFlairsStartingWith(String prefix, {required int limit});
}
