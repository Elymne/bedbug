/// Une page de résultats d'une liste paginée, et de quoi demander la suivante.
///
/// La pagination se fait par curseur et non par décalage : un décalage (`OFFSET`) donne des doublons ou des trous dès
/// que la liste change pendant qu'on la parcourt (contenus reçus par échange, scores recalculés). Le curseur est opaque :
/// seule l'implémentation du repository qui l'a produit sait le relire, les use cases et l'application le renvoient
/// tel quel pour obtenir la page suivante.
class CursorPage<T> {
  /// Crée une page.
  ///
  /// [items] : éléments de la page, dans l'ordre de la liste.
  /// [nextCursor] : curseur de la page suivante, null quand la liste est épuisée.
  const CursorPage({required this.items, required this.nextCursor});

  /// Éléments de la page, dans l'ordre de la liste.
  final List<T> items;

  /// Curseur à fournir pour obtenir la page suivante, null quand il n'y a plus rien.
  final String? nextCursor;

  /// Indique s'il reste des éléments après cette page.
  bool get hasMore {
    return nextCursor != null;
  }
}
