import 'package:bedbug/features/content/domain/entities/content.dart';

/// Contenu de type lien, composé d'un titre, d'un corps et d'une URL.
class LinkContent extends Content {
  /// Crée un [LinkContent].
  ///
  /// - [title] : titre du lien.
  /// - [body] : description du lien.
  /// - [url] : URL pointée par ce contenu.
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
    required this.body,
    required this.url,
    this.ogImageUrl,
    this.ogTitle,
    this.ogDescription,
  });

  /// Titre du lien.
  final String title;

  /// Description du lien.
  final String body;

  /// URL pointée par ce contenu.
  final String url;

  /// URL de l'image Open Graph. `null` si non fetchée ou absente.
  final String? ogImageUrl;

  /// Titre Open Graph. `null` si non fetché ou absent.
  final String? ogTitle;

  /// Description Open Graph. `null` si non fetchée ou absente.
  final String? ogDescription;
}
