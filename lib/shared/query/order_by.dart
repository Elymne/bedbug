/// Paramètre de tri pour une requête [getMany].
///
/// [field] correspond au nom du champ tel qu'il est stocké en base de données.
class OrderBy {
  /// Crée un [OrderBy] sur le [field] donné.
  ///
  /// - [field] : nom du champ sur lequel trier.
  /// - [descending] : `true` pour un tri décroissant. Défaut : `false`.
  const OrderBy(this.field, {this.descending = false});

  /// Nom du champ sur lequel appliquer le tri.
  final String field;

  /// Indique si le tri est décroissant.
  final bool descending;
}
