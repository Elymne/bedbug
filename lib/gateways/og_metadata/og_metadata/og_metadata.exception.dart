/// Exception levée lorsque l'aperçu (Open Graph) d'une page ne peut pas être lu.
///
/// Levée dans les gateways d'aperçu : réseau indisponible, délai dépassé, redirection refusée ou réponse vide.
class OgMetadataException implements Exception {
  /// Crée une [OgMetadataException].
  ///
  /// - [source] : nom du gateway où l'erreur s'est produite.
  /// - [cause] : erreur originale ayant déclenché l'exception.
  const OgMetadataException(this.source, this.cause);

  /// Nom du gateway où l'erreur s'est produite.
  final String source;

  /// Erreur originale ayant déclenché l'exception.
  final Object cause;

  @override
  String toString() {
    return 'OgMetadataException[$source]: $cause';
  }
}
