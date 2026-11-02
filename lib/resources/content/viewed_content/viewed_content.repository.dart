import 'package:bedbug/resources/content/viewed_content/viewed_content.entity.dart';

/// Contrat du repository mémorisant les contenus que l'utilisateur a eus à l'écran.
///
/// À ne pas confondre avec `SeenContentRepository`, qui retient ce que le téléphone a déjà reçu, pour ne pas le
/// retélécharger : un contenu reçu y figure dès son arrivée, avant même que l'utilisateur ait pu le voir.
abstract class ViewedContentRepository {
  /// Retourne les identifiants des contenus déjà vus par l'utilisateur.
  Future<Set<String>> getAllIds();

  /// Mémorise [entity], le passage d'un contenu à l'écran.
  ///
  /// - [entity] : contenu vu, identifié par l'identifiant du contenu.
  Future<void> addOne(ViewedContent entity);

  /// Oublie les contenus [ids], supprimés du téléphone.
  ///
  /// - [ids] : identifiants des contenus à oublier.
  Future<void> deleteMany(Iterable<String> ids);
}
