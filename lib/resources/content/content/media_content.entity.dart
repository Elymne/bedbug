import 'package:bedbug/resources/content/content/content.config.dart';
import 'package:bedbug/resources/content/content/content.entity.dart';

/// Contenu regroupant une ou plusieurs images, gifs ou vidéos hébergés sur des sites reconnus.
///
/// Le contenu ne transporte que les adresses des médias : il reste aussi
/// léger qu'un contenu texte à transférer de pair à pair, quelle que soit la
/// taille des médias.
class MediaContent extends Content {
  /// Crée un [MediaContent].
  ///
  /// - [media] : médias du contenu, dans l'ordre d'affichage (au moins un, au plus [maxMediaPerContent]).
  /// - [title] : titre accompagnant les médias.
  /// - [body] : description optionnelle accompagnant les médias.
  MediaContent({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.signatureId,
    required super.origin,
    required super.broadcastScore,
    required super.survivalScore,
    required super.displayScore,
    required super.bounce,
    required super.sizeInBytes,
    required super.flair,
    super.tags,
    required this.media,
    required this.title,
    this.body,
  });

  /// Médias du contenu, dans l'ordre d'affichage.
  final List<ContentMedia> media;

  /// Titre accompagnant les médias.
  final String title;

  /// Description optionnelle accompagnant les médias.
  final String? body;

  /// Recrée ce [MediaContent] avec ses scores mis à jour, pour permettre au
  /// use case de recalcul de persister la nouvelle valeur sans connaître le
  /// détail des champs propres à ce sous-type.
  @override
  MediaContent copyWithScores({double? broadcastScore, double? survivalScore, double? displayScore}) {
    return MediaContent(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      signatureId: signatureId,
      origin: origin,
      broadcastScore: broadcastScore ?? this.broadcastScore,
      survivalScore: survivalScore ?? this.survivalScore,
      displayScore: displayScore ?? this.displayScore,
      bounce: bounce,
      sizeInBytes: sizeInBytes,
      flair: flair,
      tags: tags,
      media: media,
      title: title,
      body: body,
    );
  }

  /// Recrée ce [MediaContent] avec un [sizeInBytes] mis à jour, pour
  /// permettre au use case de sauvegarde de persister le poids réel sans
  /// connaître le détail des champs propres à ce sous-type.
  @override
  MediaContent copyWithSizeInBytes(int sizeInBytes) {
    return MediaContent(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      signatureId: signatureId,
      origin: origin,
      broadcastScore: broadcastScore,
      survivalScore: survivalScore,
      displayScore: displayScore,
      bounce: bounce,
      sizeInBytes: sizeInBytes,
      flair: flair,
      tags: tags,
      media: media,
      title: title,
      body: body,
    );
  }

  /// Recrée ce [MediaContent] avec les champs fixés à la réception, pour permettre au use case d'import de les
  /// appliquer sans connaître le détail des champs propres à ce sous-type.
  @override
  MediaContent copyWithReception({
    required String signatureId,
    required int bounce,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String flair,
  }) {
    return MediaContent(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      signatureId: signatureId,
      origin: origin,
      broadcastScore: broadcastScore,
      survivalScore: survivalScore,
      displayScore: displayScore,
      bounce: bounce,
      sizeInBytes: sizeInBytes,
      flair: flair,
      tags: tags,
      media: media,
      title: title,
      body: body,
    );
  }
}

/// Un média d'un `MediaContent` : une image, un gif ou une vidéo hébergé sur un site reconnu.
///
/// Seule l'adresse voyage de pair à pair, jamais le fichier : transférer
/// des fichiers par Wi-Fi ou BLE est trop lourd, et trop risqué (n'importe
/// qui pourrait diffuser n'importe quelle image). L'adresse est conservée
/// telle que saisie : elle est vérifiée à chaque affichage, contre les
/// listes de domaines de l'utilisateur qui la reçoit.
class ContentMedia {
  /// Crée un [ContentMedia].
  ///
  /// - [url] : adresse du média, telle que saisie par l'auteur.
  /// - [kind] : nature du média, qui décide de la façon de l'afficher.
  const ContentMedia({required this.url, required this.kind});

  /// Adresse du média, telle que saisie par l'auteur.
  final String url;

  /// Nature du média.
  final MediaKind kind;

  @override
  bool operator ==(Object other) {
    return other is ContentMedia && other.url == url && other.kind == kind;
  }

  @override
  int get hashCode {
    return Object.hash(url, kind);
  }
}

/// Nature d'un [ContentMedia].
enum MediaKind {
  /// Image fixe.
  image(0),

  /// Image animée.
  gif(1),

  /// Vidéo, lue par un lecteur.
  video(2);

  const MediaKind(this.value);

  /// Valeur entière persistée. Stable indépendamment de l'ordre de déclaration.
  final int value;

  /// Retourne la nature correspondant à [value], ou [image] si elle est inconnue.
  ///
  /// - [value] : valeur entière persistée.
  static MediaKind fromValue(int value) {
    for (final kind in MediaKind.values) {
      if (kind.value == value) {
        return kind;
      }
    }
    return image;
  }
}
