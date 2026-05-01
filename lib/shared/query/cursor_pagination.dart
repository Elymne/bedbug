import 'package:bedbug/shared/query/pagination_params.dart';

/// Paramètres de pagination par curseur pour une requête [getMany].
///
/// La navigation se fait séquentiellement : [cursor] pointe vers le dernier
/// document de la page précédente. `null` indique la première page.
class CursorPagination extends PaginationParams {
  /// Crée une [CursorPagination] avec les paramètres fournis.
  ///
  /// - [pageSize] : nombre maximum de résultats par page. Défaut : 20.
  /// - [cursor] : identifiant du dernier document de la page précédente.
  ///   `null` pour la première page.
  const CursorPagination({super.pageSize = 20, this.cursor});

  /// Identifiant du dernier document retourné lors de la page précédente.
  ///
  /// `null` indique que la requête part du début de la collection.
  final String? cursor;
}
