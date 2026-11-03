/// Contrat du journal des erreurs imprévues.
abstract class ErrorLogRepository {
  /// Enregistre une erreur imprévue attrapée par un use case.
  ///
  /// Appelée depuis le dernier `catch` d'un use case, là où plus rien ne peut rattraper une nouvelle erreur : cette
  /// méthode ne lève donc jamais. Un échec d'écriture du journal est seulement logué.
  ///
  /// - [source] : nom du use case qui a attrapé l'erreur.
  /// - [error] : erreur attrapée.
  /// - [stackTrace] : pile d'appels associée.
  Future<void> record({required String source, required Object error, required StackTrace stackTrace});
}
