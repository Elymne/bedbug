import 'package:bedbug/core/domain/value_object.dart';
import 'package:bedbug/resources/url/safe_url/safe_url.value_object.dart';

/// Contrat de lecture de l'aperçu (Open Graph) d'une page web.
///
/// Un lien partagé s'affiche mieux avec son image, son titre et sa description : la page les déclare dans ses
/// balises `og:*`. Les lire, c'est contacter le site : l'appelant décide s'il en a le droit.
abstract class OgMetadataGateway {
  /// Retourne l'aperçu Open Graph de la page [url].
  ///
  /// Ne suit aucune redirection : seul le domaine de [url] a été vérifié, une redirection pourrait mener n'importe
  /// où. Lève une `OgMetadataException` si la page ne peut pas être lue (réseau, délai dépassé, redirection, réponse
  /// vide).
  ///
  /// - [url] : adresse vérifiée de la page.
  Future<OgMetadata> fetch(SafeUrl url);
}

/// Métadonnées Open Graph extraites d'une page web.
class OgMetadata extends ValueObject {
  /// Crée un [OgMetadata].
  ///
  /// - [imageUrl] : URL de l'image `og:image`, résolue en adresse complète.
  /// - [title] : titre `og:title`.
  /// - [description] : description `og:description`.
  const OgMetadata({this.imageUrl, this.title, this.description});

  /// URL de l'image Open Graph, résolue en adresse complète.
  final String? imageUrl;

  /// Titre Open Graph.
  final String? title;

  /// Description Open Graph.
  final String? description;
}
