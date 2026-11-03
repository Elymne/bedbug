/// Exception levée lorsque la couche de stockage rencontre une erreur.
///
/// Indique un problème sur la **source de données** : box Hive fermée,
/// disque plein, corruption du fichier de stockage. Levée dans les
/// repositories lors des opérations de lecture ou d'écriture.
class DatasourceException implements Exception {
  /// Crée une [DatasourceException].
  ///
  /// - [source] : nom du repository où l'erreur s'est produite.
  /// - [cause] : erreur originale ayant déclenché l'exception.
  const DatasourceException(this.source, this.cause);

  /// Nom du repository où l'erreur s'est produite.
  final String source;

  /// Erreur originale ayant déclenché l'exception.
  final Object cause;

  @override
  String toString() => 'DatasourceException[$source]: $cause';
}
