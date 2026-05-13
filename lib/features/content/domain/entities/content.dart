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
    required this.bounce,
    required this.senderId,
    this.subId,
  });

  /// Identifiant de l'auteur du contenu.
  final String authorId;

  /// Priorité du contenu, utilisée pour ordonner la suppression automatique
  /// lors d'un nettoyage du stockage local.
  final ContentPriority priority;

  /// Nombre de rebonds du contenu, c'est-à-dire le nombre de fois qu'il a
  /// été retransmis d'appareil en appareil.
  final int bounce;

  /// Identifiant de l'appareil ou de l'utilisateur ayant transmis ce contenu
  /// à l'appareil local.
  final String senderId;

  /// Identifiant du sub auquel appartient ce contenu.
  /// `null` si le contenu est purement public.
  final String? subId;
}
