/// Échecs possibles des use cases de lecture et d'écriture des réglages de confiance.
enum TrustSettingsFailure {
  /// Les réglages lus sont corrompus.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue.
  unknown,
}
