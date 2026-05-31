/// Exception levée lorsque la donnée lue est invalide ou corrompue.
///
/// Indique un problème sur la **donnée elle-même** : schéma invalide,
/// champ manquant, type inattendu. Levée dans les méthodes `toEntity()`
/// des modèles lors de la désérialisation.
class DataException implements Exception {
  /// Crée une [DataException].
  ///
  /// - [source] : nom du modèle où l'erreur s'est produite.
  /// - [cause] : erreur originale ayant déclenché l'exception.
  const DataException(this.source, this.cause);

  /// Nom du modèle où la désérialisation a échoué.
  final String source;

  /// Erreur originale ayant déclenché l'exception.
  final Object cause;

  @override
  String toString() => 'DataException[$source]: $cause';
}
