/// Exception levée lorsqu'un média ne peut pas être enregistré dans la galerie du téléphone.
///
/// Levée dans les gateways de galerie. [isAccessDenied] distingue un refus
/// d'accès de l'utilisateur, qu'on lui explique, d'une autre erreur
/// (stockage plein, format refusé, erreur native).
class GalleryException implements Exception {
  /// Crée une [GalleryException].
  ///
  /// - [source] : nom du gateway où l'erreur s'est produite.
  /// - [cause] : erreur originale ayant déclenché l'exception.
  /// - [isAccessDenied] : `true` si l'utilisateur a refusé l'accès à sa galerie.
  const GalleryException(this.source, this.cause, {this.isAccessDenied = false});

  /// Nom du gateway où l'erreur s'est produite.
  final String source;

  /// Erreur originale ayant déclenché l'exception.
  final Object cause;

  /// Indique si l'utilisateur a refusé l'accès à sa galerie.
  final bool isAccessDenied;

  @override
  String toString() {
    return 'GalleryException[$source]: $cause';
  }
}
