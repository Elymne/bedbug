import 'package:bedbug/core/domain/entity.dart';

/// Trace qu'un contenu est passé à l'écran de l'utilisateur.
///
/// Le fil d'accueil met en avant ce que l'utilisateur n'a pas encore vu : il faut donc se souvenir de ce qui a déjà
/// défilé sous ses yeux. [id] est l'identifiant du contenu vu, et [createdAt] le moment où il l'a vu.
///
/// Entité à part du contenu plutôt qu'un champ : marquer un contenu comme vu arrive à chaque défilement, et ne doit
/// pas réécrire le contenu entier.
class ViewedContent extends Entity {
  /// Crée un [ViewedContent].
  ///
  /// - [id] : identifiant du contenu vu.
  /// - [createdAt] : moment où le contenu a été vu.
  /// - [updatedAt] : date de dernière mise à jour.
  ViewedContent({required super.id, required super.createdAt, required super.updatedAt});
}
