import 'package:bedbug/shared/domain/value_object.dart';

/// Un média d'un `MediaContent` : une image, un gif ou une vidéo hébergé sur un site reconnu.
///
/// Seule l'adresse voyage de pair à pair, jamais le fichier : transférer
/// des fichiers par Wi-Fi ou BLE est trop lourd, et trop risqué (n'importe
/// qui pourrait diffuser n'importe quelle image). L'adresse est conservée
/// telle que saisie : elle est vérifiée à chaque affichage, contre les
/// listes de domaines de l'utilisateur qui la reçoit.
class ContentMedia extends ValueObject {
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
