import 'package:bedbug/shared/domain/repository.dart';
import 'package:bedbug/shared/query/cursor_pagination.dart';
import 'package:bedbug/shared/query/offset_pagination.dart';

/// Résultat paginé d'une requête [Repository.getMany].
///
/// [T] est le type des entités retournées.
/// [total] représente le nombre total de documents correspondant aux filtres
/// appliqués, indépendamment de la pagination.
///
/// Selon la stratégie de pagination utilisée, seul l'un des deux champs de
/// navigation est renseigné :
/// - [nextCursor] pour la pagination par curseur (Firestore).
/// - [nextOffset] pour la pagination par décalage.
class Page<T> {
  /// Crée un [Page] avec les [items], le [total] et les informations de
  /// navigation fournies.
  ///
  /// - [nextCursor] : identifiant opaque du dernier document retourné, pour la
  ///   pagination par curseur. `null` si dernière page.
  /// - [nextOffset] : décalage à utiliser pour la page suivante, pour la
  ///   pagination par offset. `null` si dernière page.
  const Page({required this.items, required this.total, this.nextCursor, this.nextOffset});

  /// Documents retournés pour la page courante.
  final List<T> items;

  /// Nombre total de documents correspondant aux filtres, toutes pages
  /// confondues.
  final int total;

  /// Identifiant du dernier document retourné.
  ///
  /// À passer comme [CursorPagination.cursor] pour charger la page suivante.
  /// `null` si la stratégie utilisée est [OffsetPagination] ou si la page
  /// courante est la dernière.
  final String? nextCursor;

  /// Décalage de la page suivante.
  ///
  /// À passer comme [OffsetPagination.offset] pour charger la page suivante.
  /// `null` si la stratégie utilisée est [CursorPagination] ou si la page
  /// courante est la dernière.
  final int? nextOffset;

  /// Indique s'il existe une page suivante, quelle que soit la stratégie de
  /// pagination.
  bool get hasNextPage => nextCursor != null || nextOffset != null;
}
