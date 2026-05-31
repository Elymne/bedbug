/// Exception levée lorsque la page demandée dans [Repository.getMany] n'existe pas.
class PageNotFoundException implements Exception {
  /// Crée une [PageNotFoundException].
  ///
  /// - [source] : nom du repository ou de la datasource à l'origine de l'exception.
  /// - [page] : numéro de page demandé.
  const PageNotFoundException(this.source, this.page);

  /// Nom du repository à l'origine de l'exception.
  final String source;

  /// Numéro de page demandé qui n'existe pas.
  final int page;

  @override
  String toString() {
    return 'PageNotFoundException($source): page $page does not exist';
  }
}
