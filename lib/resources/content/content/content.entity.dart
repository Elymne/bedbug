import 'dart:convert';

import 'package:bedbug/core/domain/entity.dart';
import 'package:bedbug/resources/content/content/content_origin.enum.dart';
import 'package:bedbug/resources/content/content/drawing_content.entity.dart';
import 'package:bedbug/resources/content/content/link_content.entity.dart';
import 'package:bedbug/resources/content/content/media_content.entity.dart';
import 'package:bedbug/resources/content/content/tag.enum.dart';
import 'package:bedbug/resources/content/content/text_content.entity.dart';
import 'package:bedbug/resources/content/drawing/drawing.value_object.dart';
import 'package:bedbug/resources/signature/signature/signature.entity.dart';

/// Classe abstraite représentant un contenu publié par un utilisateur.
///
/// Tout type de contenu (post, commentaire, etc.) étend cette classe.
/// La référence à l'auteur est portée par [signatureId] uniquement,
/// sans couplage direct à l'entité [Signature].
abstract class Content extends Entity {
  /// Crée un [Content].
  ///
  /// - [signatureId] : identifiant de la signature de l'auteur.
  /// - [origin] : provenance du contenu, facteur d'entrée des scores
  ///   [broadcastScore] et [survivalScore].
  /// - [broadcastScore] : probabilité de diffusion prioritaire en BLE/WIFI.
  /// - [survivalScore] : probabilité de conservation lors d'un nettoyage
  ///   automatique du stockage local.
  /// - [displayScore] : priorité d'affichage dans la liste de la page d'accueil.
  /// - [flair] : étiquette libre de l'auteur, sans le `/` initial (ex. `france`).
  Content({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.signatureId,
    required this.origin,
    required this.broadcastScore,
    required this.survivalScore,
    required this.displayScore,
    required this.bounce,
    required this.sizeInBytes,
    required this.flair,
    this.tags = const [],
  });

  /// Identifiant de la signature de l'auteur du contenu.
  ///
  /// Vaut `local` pour la signature de l'utilisateur, `anonymous` pour un contenu anonyme, et `peer-<empreinte>`
  /// pour une signature reçue d'un pair. Une signature n'est qu'un style : cet identifiant ne prouve pas qui a
  /// écrit le contenu.
  final String signatureId;

  /// Provenance du contenu (public, abonné, favori, possédé), utilisée comme
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

  /// Poids du contenu en octets, calculé à la réception du wrap.
  ///
  /// Pour les contenus pointant vers un fichier (ex. image),
  /// correspond à la taille du fichier sur disque.
  final int sizeInBytes;

  /// Étiquette libre écrite à la main par l'auteur, affichée en tête du
  /// contenu sous la forme `/flair` (ex. `/france`).
  ///
  /// Contrairement aux [tags], issus d'un catalogue fermé, le flair est un
  /// texte libre : il permet à l'auteur de rattacher son contenu à un thème
  /// ou un lieu sans structure préalable. Obligatoire : tout contenu est
  /// rattaché à un flair. Stocké sans le `/` initial, déjà normalisé via
  /// `FlairExtension`.
  final String flair;

  /// Tags associés à ce contenu, parmi le catalogue statique [Tag].
  final List<Tag> tags;

  /// Indique si ce contenu a été créé sur cet appareil, par son utilisateur.
  ///
  /// S'appuie sur [origin] et non sur [signatureId] : un contenu publié en
  /// anonyme porte l'identifiant anonyme, mais reste le nôtre. L'origine est
  /// propre à chaque appareil (un pair qui reçoit ce contenu lui attribue sa
  /// propre origine), elle ne permet donc à personne d'autre de se faire
  /// passer pour l'auteur.
  bool get isOwned {
    return origin == ContentOrigin.owned;
  }

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

  /// Retourne une copie de ce contenu reçu d'un pair, avec les champs propres à l'appareil fixés, en conservant
  /// le type concret d'origine.
  ///
  /// Un contenu reçu ne transporte pas d'auteur, et ses dates, son nombre de rebonds et son flair viennent d'un
  /// pair qui peut mentir : le use case d'import les recalcule ou les borne, puis les applique via cette méthode,
  /// sans connaître ni reconstruire le sous-type concret (texte, lien, média, dessin).
  ///
  /// - [signatureId] : identifiant local de la signature de l'auteur.
  /// - [bounce] : nombre de rebonds, celui du pair plus un.
  /// - [createdAt] : date de création, bornée à la date du jour.
  /// - [updatedAt] : date de mise à jour, bornée à la date du jour.
  /// - [flair] : flair normalisé.
  Content copyWithReception({
    required String signatureId,
    required int bounce,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String flair,
  });

  /// Retourne le poids réel de [content], selon son type concret.
  ///
  /// Le poids ([sizeInBytes]) porté par un contenu n'est pas fiable : un contenu reçu d'un pair pourrait mentir sur sa
  /// taille pour échapper aux limites de stockage. Tout enregistrement recalcule donc le poids avec cette méthode.
  ///
  /// Somme des octets UTF-8 de ses champs texte, calculable directement depuis les données du domaine. Un
  /// [MediaContent] ne stocke que les adresses de ses médias, jamais les fichiers : son poids est celui de ces
  /// adresses. Un [DrawingContent] pèse son titre et ses opérations.
  ///
  /// - [content] : contenu à peser.
  static int sizeInBytesOf(Content content) {
    if (content is TextContent) {
      return utf8.encode(content.title).length + utf8.encode(content.body).length;
    }

    if (content is LinkContent) {
      final fields = [
        content.title,
        content.url,
        content.body,
        content.ogTitle,
        content.ogDescription,
        content.ogImageUrl,
      ];
      return fields.whereType<String>().fold<int>(0, (total, field) => total + utf8.encode(field).length);
    }

    if (content is MediaContent) {
      final fields = [content.title, content.body, for (final media in content.media) media.url];
      return fields.whereType<String>().fold<int>(0, (total, field) => total + utf8.encode(field).length);
    }

    if (content is DrawingContent) {
      return utf8.encode(content.title).length + _drawingSizeInBytes(content.drawing);
    }

    return content.sizeInBytes;
  }

  /// Retourne le poids maximal de [drawing] une fois stocké.
  ///
  /// Une borne haute plutôt que le poids exact de son encodage, qui dépend du stockage : 4 octets par couleur, 12 par
  /// opération et 4 par point.
  ///
  /// - [drawing] : dessin à peser.
  static int _drawingSizeInBytes(Drawing drawing) {
    var total = drawing.palette.length * 4;
    for (final operation in drawing.operations) {
      total += 12;
      if (operation is DrawingStroke) {
        total += operation.points.length * 4;
      }
    }
    return total;
  }
}
