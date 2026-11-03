/// Classe abstraite de base pour toutes les entités persistées.
///
/// Fournit les champs de traçabilité communs : identifiant unique,
/// date de création et date de dernière mise à jour. Ces champs sont
/// gérés par la couche Infrastructure et ne doivent jamais être utilisés
/// dans la logique métier.
abstract class Entity {
  /// Crée un [Entity] avec ses champs de traçabilité.
  ///
  /// - [id] : identifiant unique (UID Firebase ou équivalent).
  /// - [createdAt] : date de création de l'enregistrement.
  /// - [updatedAt] : date de dernière mise à jour de l'enregistrement.
  Entity({required this.id, required this.createdAt, required this.updatedAt});

  /// Identifiant unique de l'entité.
  final String id;

  /// Date de création de l'enregistrement.
  final DateTime createdAt;

  /// Date de dernière mise à jour de l'enregistrement.
  final DateTime updatedAt;
}
