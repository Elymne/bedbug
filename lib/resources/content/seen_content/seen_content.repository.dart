import 'package:bedbug/resources/content/seen_content/seen_content.entity.dart';

/// Contrat du repository mémorisant les contenus déjà reçus ou supprimés.
///
/// Un contenu supprimé (par l'utilisateur ou par le nettoyage du stockage) disparaît de la base : sans cette
/// mémoire, le prochain pair qui le propose le ferait retélécharger, en boucle. Seuls les identifiants sont
/// gardés, et seulement un temps : un contenu assez vieux pour être oublié n'est de toute façon presque plus
/// proposé par les pairs.
abstract class SeenContentRepository {
  /// Mémorise [entities], identifiés par l'identifiant de leur contenu.
  ///
  /// - [entities] : contenus reçus ou supprimés.
  Future<void> addMany(Iterable<SeenContent> entities);

  /// Retourne, parmi [ids], ceux déjà mémorisés.
  ///
  /// - [ids] : identifiants de contenus à vérifier.
  Future<Set<String>> getSeenAmong(Set<String> ids);

  /// Oublie les contenus mémorisés avant [date].
  ///
  /// - [date] : date limite, exclue.
  Future<void> deleteSeenBefore(DateTime date);
}
