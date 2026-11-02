/// Échecs possibles des use cases de lecture et d'écriture du brouillon de dessin.
enum DrawingDraftFailure {
  /// Le brouillon lu est corrompu.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue.
  unknown,
}
