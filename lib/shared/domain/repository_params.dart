import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/order_by.dart';

/// Classe de base abstraite pour les paramètres d'une requête [Repository.getMany].
///
/// Porte les paramètres communs à tous les repositories : tri, pagination et limite.
/// Chaque repository déclare une sous-classe concrète qui y ajoute ses propres filtres métier.
abstract class RepositoryParams extends Params {
  /// Crée des [RepositoryParams].
  ///
  /// - [page] : numéro de la page demandée, commence à 1. Par défaut 1.
  /// - [limit] : nombre maximum d'éléments à retourner. `null` = tous les éléments.
  /// - [orderBy] : tri sur un champ unique. `null` = ordre par défaut.
  const RepositoryParams({this.page = 1, this.limit, this.orderBy});

  /// Numéro de la page demandée. Commence à 1.
  final int page;

  /// Nombre maximum d'éléments à retourner. `null` = tous les éléments sans limite.
  final int? limit;

  /// Tri appliqué à la requête. `null` = ordre naturel de la collection.
  final OrderBy? orderBy;
}
