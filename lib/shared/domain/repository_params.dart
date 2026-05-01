import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/query/order_by.dart';
import 'package:bedbug/shared/query/pagination_params.dart';

/// Classe de base abstraite pour les paramètres d'une requête [getMany].
///
/// Porte les paramètres communs à tous les repositories : tri et pagination.
/// Le type générique [P] définit la stratégie de pagination utilisée :
/// [CursorPagination] pour Firestore, [OffsetPagination] pour les backends
/// à décalage.
///
/// Chaque repository déclare une sous-classe concrète qui y ajoute ses propres
/// filtres métier.
abstract class RepositoryParams<P extends PaginationParams> extends Params {
  /// Crée des [RepositoryParams] avec le [orderBy] et la [pagination] fournis.
  ///
  /// - [orderBy] : tri sur un champ unique. `null` = ordre par défaut.
  /// - [pagination] : paramètres de pagination. `null` = retourne tous les
  ///   résultats sans pagination.
  const RepositoryParams({this.pagination, this.orderBy});

  /// Tri appliqué à la requête. `null` = ordre naturel de la collection.
  final OrderBy? orderBy;

  /// Paramètres de pagination selon la stratégie du repository.
  /// `null` = retourne tous les résultats sans limite de page.
  final P? pagination;
}
