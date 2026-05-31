import 'package:dio/dio.dart';

/// Métadonnées Open Graph extraites d'une page web.
class OgMetadata {
  /// Crée un [OgMetadata].
  ///
  /// - [imageUrl] : URL de l'image `og:image`.
  /// - [title] : titre `og:title`.
  /// - [description] : description `og:description`.
  const OgMetadata({this.imageUrl, this.title, this.description});

  /// URL de l'image Open Graph.
  final String? imageUrl;

  /// Titre Open Graph.
  final String? title;

  /// Description Open Graph.
  final String? description;
}

/// Service de récupération des métadonnées Open Graph d'une URL.
///
/// Effectue un GET HTTP sur l'URL cible et extrait les balises `og:image`,
/// `og:title` et `og:description` depuis le HTML de la réponse.
class OgMetadataService {
  /// Crée un [OgMetadataService].
  OgMetadataService();

  final _dio = Dio();

  /// Retourne les métadonnées OG de [url].
  ///
  /// Retourne un [OgMetadata] avec tous les champs à `null` en cas d'erreur.
  Future<OgMetadata> fetch(String url) async {
    try {
      final response = await _dio.get<String>(
        url,
        options: Options(headers: {'User-Agent': 'Mozilla/5.0'}, responseType: ResponseType.plain),
      );
      final html = response.data;
      if (html == null) return const OgMetadata();
      return _extractMetadata(html);
    } catch (_) {
      return const OgMetadata();
    }
  }

  /// Extrait les métadonnées OG depuis le [html] brut.
  OgMetadata _extractMetadata(String html) {
    return OgMetadata(
      imageUrl: _extractProperty(html, 'og:image'),
      title: _extractProperty(html, 'og:title'),
      description: _extractProperty(html, 'og:description'),
    );
  }

  /// Extrait la valeur de la balise `<meta property="[property]">` dans [html].
  String? _extractProperty(String html, String property) {
    final metaRegex = RegExp('<meta[^>]+$property[^>]+>', caseSensitive: false);
    final metaMatch = metaRegex.firstMatch(html);
    if (metaMatch == null) return null;
    final contentRegex = RegExp(r"""content=["']([^"']+)["']""", caseSensitive: false);
    return contentRegex.firstMatch(metaMatch.group(0)!)?.group(1);
  }
}
