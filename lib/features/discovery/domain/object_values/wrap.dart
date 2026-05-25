/// Enveloppe autour d'un contenu chiffré reçu via le réseau.
///
/// Le champ [keyId] correspond au `subId` du portefeuille contenant les clés
/// nécessaires au déchiffrement. `null` indique un contenu public transitant
/// en clair — [payload] peut alors être lu directement sans déchiffrement.
class Wrap {
  /// Crée un [Wrap].
  ///
  /// - [keyId] : identifiant du portefeuille de clés à utiliser.
  ///   `null` si le contenu est public et transite en clair.
  /// - [payload] : contenu brut, chiffré si [keyId] est renseigné,
  ///   en clair sinon.
  const Wrap({this.keyId, required this.payload});

  /// Identifiant du portefeuille de clés permettant de déchiffrer ce contenu.
  /// `null` si le contenu est public.
  final String? keyId;

  /// Contenu brut. Chiffré si [keyId] est renseigné, en clair sinon.
  final String payload;
}
