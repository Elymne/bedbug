import 'package:bedbug/core/config/http_config.dart';
import 'package:bedbug/gateways/og_metadata/og_metadata/og_metadata.exception.dart';
import 'package:bedbug/gateways/og_metadata/og_metadata/og_metadata.gateway.dart';
import 'package:bedbug/resources/url/safe_url/safe_url.value_object.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [DioOgMetadataGateway].
final ogMetadataGatewayProvider = Provider<OgMetadataGateway>((ref) => DioOgMetadataGateway());

/// Implémentation de [OgMetadataGateway] avec Dio : un GET de la page, puis l'extraction des balises `og:*`.
class DioOgMetadataGateway implements OgMetadataGateway {
  /// Crée un [DioOgMetadataGateway].
  DioOgMetadataGateway();

  /// Client HTTP qui ne suit pas les redirections et abandonne vite une page trop lente.
  final _dio = Dio(
    BaseOptions(
      followRedirects: false,
      maxRedirects: 0,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'User-Agent': appUserAgent},
    ),
  );

  @override
  Future<OgMetadata> fetch(SafeUrl url) async {
    try {
      final response = await _dio.get<String>(url.url, options: Options(responseType: ResponseType.plain));
      final html = response.data;
      if (html == null) {
        throw const OgMetadataException('DioOgMetadataGateway', 'empty response');
      }
      return _extractMetadata(html, url.url);
    } on DioException catch (error) {
      throw OgMetadataException('DioOgMetadataGateway', error);
    }
  }

  /// Extrait les métadonnées OG depuis le [html] brut de la page [pageUrl].
  ///
  /// L'image d'aperçu peut être donnée relativement à la page : elle est alors résolue en adresse complète, vérifiée
  /// plus tard à l'affichage.
  ///
  /// - [html] : contenu HTML de la page.
  /// - [pageUrl] : adresse de la page, pour résoudre une image relative.
  OgMetadata _extractMetadata(String html, String pageUrl) {
    final imageUrl = _extractProperty(html, 'og:image');
    return OgMetadata(
      imageUrl: imageUrl == null ? null : Uri.tryParse(pageUrl)?.resolve(imageUrl).toString(),
      title: _extractProperty(html, 'og:title'),
      description: _extractProperty(html, 'og:description'),
    );
  }

  /// Extrait la valeur de la balise `<meta property="[property]">` dans [html].
  ///
  /// - [html] : contenu HTML de la page.
  /// - [property] : nom de la propriété Open Graph recherchée.
  String? _extractProperty(String html, String property) {
    final metaRegex = RegExp('<meta[^>]+$property[^>]+>', caseSensitive: false);
    final metaMatch = metaRegex.firstMatch(html);
    if (metaMatch == null) {
      return null;
    }
    final contentRegex = RegExp(r"""content=["']([^"']+)["']""", caseSensitive: false);
    return contentRegex.firstMatch(metaMatch.group(0)!)?.group(1);
  }
}
