/// Exception levée lorsqu'une image ne peut pas être recompressée.
///
/// Indique un problème d'**encodage** : format non supporté par l'encodeur
/// natif, fichier illisible ou corrompu. Levée dans les gateways de
/// compression d'image.
class ImageCompressionException implements Exception {
  /// Crée une [ImageCompressionException].
  ///
  /// - [source] : nom du gateway où l'erreur s'est produite.
  /// - [cause] : erreur originale ayant déclenché l'exception.
  const ImageCompressionException(this.source, this.cause);

  /// Nom du gateway où l'erreur s'est produite.
  final String source;

  /// Erreur originale ayant déclenché l'exception.
  final Object cause;

  @override
  String toString() => 'ImageCompressionException[$source]: $cause';
}
