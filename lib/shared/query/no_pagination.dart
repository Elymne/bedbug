import 'package:bedbug/shared/query/pagination_params.dart';

/// Stratégie de pagination nulle — retourne tous les résultats sans limite.
///
/// À utiliser pour les repositories locaux ou les requêtes ne nécessitant
/// aucune pagination.
class NoPagination extends PaginationParams {
  /// Crée une [NoPagination].
  const NoPagination() : super(pageSize: 0);
}
