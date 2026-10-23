/// Critère de recherche des contenus à afficher.
///
/// Distingue les intentions de l'utilisateur : choisir un flair ou une
/// signature précise parmi les suggestions, ou valider sa saisie telle
/// quelle. Sert aussi d'argument au provider des résultats, d'où l'égalité
/// par valeur.
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

/// Contenus d'une signature précise, désignée par son identifiant.
///
/// Sert la page de signature, ouverte par le choix d'une signature parmi les
/// suggestions.
class SignatureSearchCriteria extends SearchCriteria {
  /// Crée un [SignatureSearchCriteria].
  ///
  /// - [signatureId] : identifiant de la signature choisie.
  const SignatureSearchCriteria(this.signatureId);

  /// Identifiant de la signature choisie.
  final String signatureId;

  @override
  bool operator ==(Object other) {
    return other is SignatureSearchCriteria && other.signatureId == signatureId;
  }

  @override
  int get hashCode {
    return Object.hash(SignatureSearchCriteria, signatureId);
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
