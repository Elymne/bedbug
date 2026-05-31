/// Résultat paginé d'une requête [Repository.getMany].
///
/// [T] est le type des entités retournées.
/// [totalItems] et [totalPages] sont optionnels — certaines implémentations
/// ne peuvent pas les calculer efficacement.
class Page<T> {
  /// Crée un [Page].
  ///
  /// - [items] : éléments de la page courante.
  /// - [hasNextPage] : indique s'il existe une page suivante.
  /// - [totalItems] : nombre total d'éléments toutes pages confondues. `null` si non calculable.
  /// - [totalPages] : nombre total de pages. `null` si non calculable.
  const Page({required this.items, required this.hasNextPage, this.totalItems, this.totalPages});

  /// Éléments de la page courante.
  final List<T> items;

  /// Indique s'il existe une page suivante.
  final bool hasNextPage;

  /// Nombre total d'éléments toutes pages confondues. `null` si non calculable.
  final int? totalItems;

  /// Nombre total de pages. `null` si non calculable.
  final int? totalPages;
}
