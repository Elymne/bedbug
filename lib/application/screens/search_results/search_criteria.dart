/// Critère de recherche ayant mené à la page de résultats.
///
/// Distingue les intentions de l'utilisateur : choisir un flair ou un auteur
/// précis parmi les suggestions, ou valider sa saisie telle quelle. Sert aussi
/// d'argument au provider des résultats, d'où l'égalité par valeur.
sealed class SearchCriteria {
  /// Constructeur constant pour permettre des sous-classes constantes.
  const SearchCriteria();
}

/// Recherche des contenus d'un flair choisi parmi les suggestions.
class FlairSearchCriteria extends SearchCriteria {
  /// Crée un [FlairSearchCriteria].
  ///
  /// - [flair] : flair choisi, sans le `/` initial.
  const FlairSearchCriteria(this.flair);

  /// Flair choisi, sans le `/` initial.
  final String flair;

  @override
  bool operator ==(Object other) {
    return other is FlairSearchCriteria && other.flair == flair;
  }

  @override
  int get hashCode {
    return Object.hash(FlairSearchCriteria, flair);
  }
}

/// Recherche des contenus d'un auteur choisi parmi les suggestions.
class AuthorSearchCriteria extends SearchCriteria {
  /// Crée un [AuthorSearchCriteria].
  ///
  /// - [authorId] : identifiant de l'auteur choisi.
  const AuthorSearchCriteria(this.authorId);

  /// Identifiant de l'auteur choisi.
  final String authorId;

  @override
  bool operator ==(Object other) {
    return other is AuthorSearchCriteria && other.authorId == authorId;
  }

  @override
  int get hashCode {
    return Object.hash(AuthorSearchCriteria, authorId);
  }
}

/// Recherche globale sur le texte validé par l'utilisateur.
class QuerySearchCriteria extends SearchCriteria {
  /// Crée un [QuerySearchCriteria].
  ///
  /// - [query] : texte validé, comparé au titre et au flair des contenus.
  const QuerySearchCriteria(this.query);

  /// Texte validé, comparé au titre et au flair des contenus.
  final String query;

  @override
  bool operator ==(Object other) {
    return other is QuerySearchCriteria && other.query == query;
  }

  @override
  int get hashCode {
    return Object.hash(QuerySearchCriteria, query);
  }
}
