import 'package:bedbug/shared/domain/order_by.dart';
import 'package:bedbug/shared/domain/params.dart';

/// Classe de base abstraite pour les paramètres d'une requête `Repository.findMany`.
///
/// Porte les paramètres communs à tous les repositories : tri et limite.
/// Chaque repository déclare une sous-classe concrète qui y ajoute ses propres filtres métier.
abstract class RepositoryParams extends Params {
  /// Crée des [RepositoryParams].
  ///
  /// - [limit] : nombre maximum d'éléments à retourner. `null` = tous les éléments.
  /// - [orderBy] : tri sur un champ unique. `null` = ordre par défaut.
  const RepositoryParams({this.limit, this.orderBy});

  /// Nombre maximum d'éléments à retourner. `null` = tous les éléments sans limite.
  final int? limit;

  /// Tri appliqué à la requête. `null` = ordre naturel de la collection.
  final OrderBy? orderBy;
}
