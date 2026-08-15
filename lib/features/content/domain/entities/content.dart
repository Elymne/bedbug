import 'package:bedbug/features/content/domain/enums/content_origin.dart';
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
  /// - [origin] : provenance du contenu, facteur d'entrée des scores
  ///   [broadcastScore] et [survivalScore].
  /// - [broadcastScore] : probabilité de diffusion prioritaire en BLE/WIFI.
  /// - [survivalScore] : probabilité de conservation lors d'un nettoyage
  ///   automatique du stockage local.
  /// - [displayScore] : priorité d'affichage dans la liste de la page d'accueil.
  Content({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.authorId,
    required this.origin,
    required this.broadcastScore,
    required this.survivalScore,
    required this.displayScore,
    required this.bounce,
    required this.senderId,
    required this.sizeInBytes,
    this.subId,
  });

  /// Identifiant de l'auteur du contenu.
  final String authorId;

  /// Provenance du contenu (public, sub, favori, possédé), utilisée comme
  /// facteur d'entrée pour le recalcul périodique des scores.
  final ContentOrigin origin;

  /// Score de probabilité de diffusion prioritaire du contenu en BLE/WIFI.
  /// Recalculé périodiquement.
  final double broadcastScore;

  /// Score de probabilité de conservation du contenu lors d'un nettoyage
  /// automatique du stockage local. Recalculé périodiquement.
  final double survivalScore;

  /// Score de priorité d'affichage du contenu dans la liste de la page
  /// d'accueil. Recalculé périodiquement.
  final double displayScore;

  /// Nombre de rebonds du contenu, c'est-à-dire le nombre de fois qu'il a
  /// été retransmis d'appareil en appareil.
  final int bounce;

  /// Identifiant de l'appareil ou de l'utilisateur ayant transmis ce contenu
  /// à l'appareil local.
  final String senderId;

  /// Poids du contenu en octets, calculé à la réception du wrap.
  ///
  /// Pour les contenus pointant vers un fichier (ex. image),
  /// correspond à la taille du fichier sur disque.
  final int sizeInBytes;

  /// Identifiant du sub auquel appartient ce contenu.
  /// `null` si le contenu est purement public.
  final String? subId;

  /// Retourne une copie de ce contenu avec [broadcastScore], [survivalScore]
  /// et/ou [displayScore] remplacés, en conservant le type concret d'origine.
  ///
  /// Les scores sont recalculés périodiquement à mesure que les contenus
  /// vieillissent ou changent de statut (favori, réception d'un rebond,
  /// etc.). Cette méthode permet aux use cases de recalcul d'appliquer les
  /// nouvelles valeurs sans connaître ni reconstruire le sous-type concret
  /// (texte, image, lien) de chaque contenu.
  Content copyWithScores({double? broadcastScore, double? survivalScore, double? displayScore});

  /// Retourne une copie de ce contenu avec [sizeInBytes] remplacé, en
  /// conservant le type concret d'origine.
  ///
  /// Le poids fourni par l'appelant à la création n'est pas fiable (un
  /// contenu reçu d'un pair pourrait mentir sur sa taille) : c'est le use
  /// case de sauvegarde qui doit déterminer le poids réel avant persistance,
  /// via cette méthode, sans connaître ni reconstruire le sous-type concret
  /// (texte, image, lien) de chaque contenu.
  Content copyWithSizeInBytes(int sizeInBytes);
}
