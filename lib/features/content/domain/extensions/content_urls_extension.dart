import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/link_content.dart';
import 'package:bedbug/features/content/domain/entities/media_content.dart';

/// Adresses externes vers lesquelles pointe un [Content], selon leur usage.
///
/// Un contenu reçu d'un pair peut pointer n'importe où : avant de l'afficher,
/// ses adresses sont confrontées aux listes de domaines de l'utilisateur.
/// Cette extension dit lesquelles, sans que le domaine du contenu ait à
/// connaître ces listes.
extension ContentUrlsExtension on Content {
  /// Adresses des médias qui décident de l'affichage du contenu : celles d'un [MediaContent].
  ///
  /// L'image d'aperçu d'un [LinkContent] n'en fait pas partie : elle n'est
  /// qu'une décoration, simplement omise si son domaine n'est pas accepté.
  List<String> get mediaUrls {
    final content = this;
    if (content is MediaContent) {
      return [for (final media in content.media) media.url];
    }
    return const [];
  }

  /// Adresses des liens du contenu : celle d'un [LinkContent].
  List<String> get linkUrls {
    final content = this;
    if (content is LinkContent) {
      return [content.url];
    }
    return const [];
  }
}
