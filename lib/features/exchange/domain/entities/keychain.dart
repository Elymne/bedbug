import 'package:bedbug/shared/domain/entity.dart';

/// Clé privée permettant de déchiffrer un contenu chiffré.
///
/// Plusieurs [PrivateKey] peuvent coexister pour un même [Keychain],
/// par exemple suite à une rotation de clés dans le temps.
class PrivateKey {
  /// Crée une [PrivateKey].
  ///
  /// - [value] : valeur brute de la clé privée.
  /// - [createdAt] : date de création, utilisée pour ordonner les clés
  ///   lors d'une rotation.
  const PrivateKey({required this.value, required this.createdAt});

  /// Valeur brute de la clé privée.
  final String value;

  /// Date de création de la clé.
  final DateTime createdAt;
}

/// Portefeuille de clés privées associé à un sub.
///
/// Un [Keychain] regroupe toutes les [PrivateKey] permettant de déchiffrer
/// les contenus d'un sub donné. Plusieurs clés peuvent coexister pour
/// un même [subId], par exemple suite à une rotation de clés.
class Keychain extends Entity {
  /// Crée un [Keychain].
  ///
  /// - [label] : libellé lisible permettant à l'utilisateur d'identifier
  ///   ce portefeuille.
  /// - [subId] : identifiant du sub dont ce portefeuille déchiffre les
  ///   contenus. Correspond au `keyId` des enveloppes reçues.
  /// - [keys] : liste des clés privées disponibles pour ce sub.
  Keychain({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.label,
    required this.subId,
    required this.keys,
  });

  /// Libellé lisible par l'utilisateur.
  final String label;

  /// Identifiant du sub associé à ce portefeuille.
  final String subId;

  /// Clés privées disponibles pour déchiffrer les contenus de ce sub.
  final List<PrivateKey> keys;
}
