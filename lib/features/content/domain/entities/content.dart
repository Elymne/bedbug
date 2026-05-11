import 'package:bedbug/features/content/domain/enums/content_priority.dart';
import 'package:bedbug/features/user/domain/entities/user.dart';
import 'package:bedbug/shared/domain/entity.dart';

/// Classe abstraite représentant un contenu publié par un utilisateur.
///
/// Tout type de contenu (post, commentaire, etc.) étend cette classe.
/// La référence à l'auteur est portée par [authorId] uniquement,
/// sans couplage direct à l'entité [User].
abstract class Content extends Entity {
  /// Crée un [Content].
  ///
  /// - [authorId] : identifiant de l'utilisateur ayant créé le contenu.
  /// - [priority] : priorité du contenu pour le nettoyage automatique du
  ///   stockage local.
  Content({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.authorId,
    required this.priority,
  });

  /// Identifiant de l'auteur du contenu.
  final String authorId;

  /// Priorité du contenu, utilisée pour ordonner la suppression automatique
  /// lors d'un nettoyage du stockage local.
  final ContentPriority priority;
}
