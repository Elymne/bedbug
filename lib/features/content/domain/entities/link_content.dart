import 'package:bedbug/features/content/domain/entities/content.dart';

/// Contenu de type lien, composé d'une URL et de métadonnées Open Graph optionnelles.
class LinkContent extends Content {
  /// Crée un [LinkContent].
  ///
  /// - [url] : URL pointée par ce contenu.
  /// - [ogImageUrl] : URL de l'image Open Graph.
  /// - [ogTitle] : titre Open Graph.
  /// - [ogDescription] : description Open Graph.
  LinkContent({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.authorId,
    required super.priority,
    required super.bounce,
    required super.senderId,
    required super.sizeInBytes,
    super.subId,
    required this.title,
    this.body,
    required this.url,
    this.ogImageUrl,
    this.ogTitle,
    this.ogDescription,
  });

  /// Titre saisi par l'utilisateur.
  final String title;

  /// Description optionnelle saisie par l'utilisateur.
  final String? body;

  /// URL pointée par ce contenu.
  final String url;

  /// URL de l'image Open Graph. `null` si non fetchée ou absente.
  final String? ogImageUrl;

  /// Titre Open Graph. `null` si non fetché ou absent.
  final String? ogTitle;

  /// Description Open Graph. `null` si non fetchée ou absente.
  final String? ogDescription;
}
