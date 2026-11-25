import 'package:bedbug/core/domain/entity.dart';

/// Trace qu'un contenu est déjà passé par le téléphone : reçu d'un pair, ou supprimé.
///
/// Un contenu supprimé (par l'utilisateur ou par le nettoyage du stockage) disparaît de la base : sans cette trace, le
/// prochain pair qui le propose le ferait retélécharger, en boucle. [id] est l'identifiant du contenu, et [createdAt]
/// le moment où il a été reçu ou supprimé, qui sert à oublier les traces trop anciennes.
class SeenContent extends Entity {
  /// Crée un [SeenContent].
  ///
  /// - [id] : identifiant du contenu.
  /// - [createdAt] : moment où le contenu a été reçu ou supprimé.
  /// - [updatedAt] : date de dernière mise à jour.
  SeenContent({required super.id, required super.createdAt, required super.updatedAt});
}
