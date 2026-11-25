import 'package:bedbug/infra/resources/content/reaction/reaction.entity.dart';

/// Contrat du repository gérant les [Reaction].
///
/// Pas de mise à jour : une réaction remplacée est supprimée puis la nouvelle enregistrée, sous son propre
/// identifiant. Une réaction n'existe que sur un contenu présent, et disparaît avec lui.
abstract class ReactionRepository {
  /// Persiste [entities] et supprime les réactions [removedIds], en une seule opération atomique.
  ///
  /// Remplacer la réaction d'un auteur et écarter celles qui dépassent le plafond d'un contenu doivent se faire
  /// ensemble : interrompu entre deux, le contenu garderait deux réactions du même auteur ou dépasserait son plafond.
  /// Une réaction de même identifiant qu'une réaction existante la met à jour.
  ///
  /// - [entities] : réactions à enregistrer.
  /// - [removedIds] : réactions à supprimer.
  Future<void> addReplacing(List<Reaction> entities, Set<String> removedIds);

  /// Retourne toutes les réactions rattachées au contenu [contentId], sans ordre garanti.
  Future<List<Reaction>> getAllByContentId(String contentId);

  /// Retourne toutes les réactions rattachées aux contenus [contentIds], sans ordre garanti.
  Future<List<Reaction>> getAllByContentIds(Set<String> contentIds);

  /// Retourne les identifiants des réactions de l'auteur [authorId] sur les contenus [contentIds].
  ///
  /// - [authorId] : identifiant de la signature de l'auteur.
  /// - [contentIds] : contenus concernés.
  Future<Set<String>> getIdsByAuthor(String authorId, Set<String> contentIds);

  /// Retourne le nombre de réactions rattachées au contenu [contentId].
  Future<int> countByContentId(String contentId);
}
