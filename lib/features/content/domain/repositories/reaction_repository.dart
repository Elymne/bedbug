import 'package:bedbug/features/content/domain/entities/reaction.dart';

/// Contrat du repository gérant les [Reaction].
///
/// Pas de mise à jour : une réaction remplacée est supprimée puis la
/// nouvelle enregistrée, sous son propre identifiant.
abstract class ReactionRepository {
  /// Persiste la réaction [entity].
  Future<void> addOne(Reaction entity);

  /// Persiste les réactions [entities] en une seule opération.
  Future<void> addMany(List<Reaction> entities);

  /// Retourne toutes les réactions rattachées au contenu [contentId], sans ordre garanti.
  Future<List<Reaction>> getAllByContentId(String contentId);

  /// Supprime les réactions dont l'identifiant fait partie de [ids].
  Future<void> deleteMany(List<String> ids);

  /// Supprime toutes les réactions rattachées au contenu [contentId].
  Future<void> deleteAllByContentId(String contentId);

  /// Supprime l'intégralité des réactions stockées.
  Future<void> deleteAll();
}
