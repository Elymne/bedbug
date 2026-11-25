import 'package:bedbug/infra/resources/content/content/content.entity.dart';

/// Résumé d'un [Content] réduit aux adresses externes vers lesquelles il pointe, rangées selon leur usage.
///
/// Confronter les contenus reçus aux listes de domaines de l'utilisateur ne demande que leurs adresses : relire chaque
/// contenu en entier (corps, dessins) pour cela coûterait une lecture de toute la base à chaque modification des
/// listes. Le repository ne lit donc que ces colonnes, et seulement pour les contenus qui ont au moins une adresse.
///
/// Lecture seule : construit uniquement par les implémentations de repository.
class ContentUrlSummary {
  /// Crée un [ContentUrlSummary].
  ///
  /// - [contentId] : identifiant du contenu résumé.
  /// - [mediaUrls] : adresses des médias du contenu, vide s'il n'en a pas.
  /// - [linkUrls] : adresses des liens du contenu, vide s'il n'en a pas.
  const ContentUrlSummary({required this.contentId, required this.mediaUrls, required this.linkUrls});

  /// Identifiant du contenu résumé.
  final String contentId;

  /// Adresses des médias du contenu, vide s'il n'en a pas.
  final List<String> mediaUrls;

  /// Adresses des liens du contenu, vide s'il n'en a pas.
  final List<String> linkUrls;

  /// Deux résumés sont égaux quand ils décrivent le même contenu avec les mêmes adresses, dans le même ordre.
  ///
  /// - [other] : objet comparé.
  @override
  bool operator ==(Object other) {
    return other is ContentUrlSummary &&
        other.contentId == contentId &&
        _isSameList(other.mediaUrls, mediaUrls) &&
        _isSameList(other.linkUrls, linkUrls);
  }

  /// Empreinte cohérente avec [operator ==].
  @override
  int get hashCode {
    return Object.hash(contentId, Object.hashAll(mediaUrls), Object.hashAll(linkUrls));
  }

  /// Représentation lisible, pour les journaux et les tests.
  @override
  String toString() {
    return 'ContentUrlSummary($contentId, médias : $mediaUrls, liens : $linkUrls)';
  }

  /// Indique si [first] et [second] contiennent les mêmes adresses dans le même ordre.
  ///
  /// - [first] : première liste comparée.
  /// - [second] : seconde liste comparée.
  static bool _isSameList(List<String> first, List<String> second) {
    if (first.length != second.length) {
      return false;
    }
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) {
        return false;
      }
    }
    return true;
  }
}
