import 'package:bedbug/shared/domain/repository.dart';
import 'package:bedbug/shared/query/cursor_pagination.dart'
    show CursorPagination;
import 'package:bedbug/shared/query/pagination_params.dart';

/// Paramètres de pagination par offset pour une requête [Repository.getMany].
///
/// À utiliser avec les base de données qui supportent nativement la pagination par décalage.
/// [CursorPagination] pour ces implémentations.
class OffsetPagination extends PaginationParams {
  /// Crée une [OffsetPagination] avec les paramètres fournis.
  ///
  /// - [pageSize] : nombre maximum de résultats par page. Défaut : 20.
  /// - [offset] : nombre de documents ignorés depuis le début du résultat
  ///   filtré. Défaut : 0.
  const OffsetPagination({super.pageSize = 20, this.offset = 0});

  /// Nombre de documents ignorés depuis le début du résultat filtré.
  final int offset;
}
