/// Codes d'erreur pour les opérations de lecture et de parsing des données.
enum DataExceptionCode {
  /// Le document lu ne respecte pas la structure attendue.
  invalidFormat,
}

/// Exception de domaine pour les erreurs d'intégrité des données.
///
/// Levée par les repositories lorsque les données reçues d'une source externe
/// (Firestore, API, etc.) ne correspondent pas à la structure des entités du domaine.
class DataException implements Exception {
  /// Crée une [DataException] avec le [code] d'erreur fourni.
  DataException(this.code);

  /// Code identifiant la nature de l'erreur.
  final DataExceptionCode code;
}
