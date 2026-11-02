/// Contrat du repository mémorisant les contenus que l'utilisateur a eus à l'écran.
///
/// À ne pas confondre avec `SeenContentRepository`, qui retient ce que le téléphone a déjà reçu, pour ne pas le
/// retélécharger : un contenu reçu y figure dès son arrivée, avant même que l'utilisateur ait pu le voir.
abstract class ViewedContentRepository {
  /// Retourne les identifiants des contenus déjà vus par l'utilisateur.
  Future<Set<String>> getAllIds();

  /// Mémorise que l'utilisateur a vu le contenu [id].
  Future<void> add(String id);

  /// Oublie les contenus [ids], supprimés du téléphone.
  Future<void> deleteMany(Iterable<String> ids);
}
