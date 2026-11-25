import 'package:bedbug/infra/resources/content/viewed_content/viewed_content.entity.dart';

/// Contrat du repository mémorisant les contenus que l'utilisateur a eus à l'écran.
///
/// À ne pas confondre avec `SeenContentRepository`, qui retient ce que le téléphone a déjà reçu, pour ne pas le
/// retélécharger : un contenu reçu y figure dès son arrivée, avant même que l'utilisateur ait pu le voir. Une trace
/// d'affichage disparaît avec son contenu.
abstract class ViewedContentRepository {
  /// Mémorise [entity], le passage d'un contenu à l'écran. Sans effet si ce contenu a déjà été vu.
  ///
  /// - [entity] : contenu vu, identifié par l'identifiant du contenu.
  Future<void> addOne(ViewedContent entity);
}
