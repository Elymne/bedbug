import 'package:bedbug/shared/query/cursor_pagination.dart'
    show CursorPagination;
import 'package:bedbug/shared/query/offset_pagination.dart'
    show OffsetPagination;

/// Classe de base abstraite pour les paramètres de pagination.
///
/// Toutes les stratégies de pagination héritent de cette classe :
/// [CursorPagination] pour Firestore, [OffsetPagination] pour les backends
/// qui supportent la pagination par décalage.
abstract class PaginationParams {
  /// Crée des [PaginationParams] avec le [pageSize] fourni.
  const PaginationParams({required this.pageSize});

  /// Nombre maximum de résultats par page.
  final int pageSize;
}
