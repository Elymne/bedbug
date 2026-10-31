/// Contrat du repository mémorisant les identifiants de contenus déjà reçus ou supprimés.
///
/// Un contenu supprimé (par l'utilisateur ou par le nettoyage du stockage) disparaît de la base : sans cette
/// mémoire, le prochain pair qui le propose le ferait retélécharger, en boucle. Seuls les identifiants sont
/// gardés, et seulement un temps : un contenu assez vieux pour être oublié n'est de toute façon presque plus
/// proposé par les pairs.
abstract class SeenContentRepository {
  /// Mémorise les identifiants [ids], vus à la date [seenAt].
  Future<void> addMany(Iterable<String> ids, DateTime seenAt);

  /// Retourne, parmi [ids], ceux déjà mémorisés.
  Future<Set<String>> getSeenAmong(Set<String> ids);

  /// Oublie les identifiants vus avant [date].
  Future<void> deleteSeenBefore(DateTime date);
}
