import 'package:bedbug/resources/content/storage/storage.value_object.dart';

/// Contrat du repository gérant la configuration [Storage].
///
/// Ce repository gère une unique configuration, toujours remplacée en entier.
abstract class StorageRepository {
  /// Retourne la configuration de stockage persistée, ou `null` si elle n'a jamais été enregistrée.
  Future<Storage?> get();

  /// Retourne le nombre d'entrées effectivement présentes dans le stockage sous-jacent, toutes clés confondues.
  ///
  /// Sert uniquement à détecter une incohérence : ce repository ne devrait jamais contenir plus d'une entrée puisqu'il
  /// gère une configuration unique. Un résultat supérieur à `1` trahit un bug (écriture sous une mauvaise clé,
  /// migration ratée, etc.), à surveiller par les use cases qui lisent cette configuration.
  Future<int> countAll();

  /// Enregistre [storage], à la place de la configuration précédente.
  ///
  /// - [storage] : configuration à enregistrer.
  Future<void> save(Storage storage);

  /// Ajoute [deltaBytes] (positif ou négatif) à `currentSizeInBytes`.
  ///
  /// Crée la configuration avec les valeurs par défaut si elle n'existe pas encore. Le résultat est toujours plafonné à
  /// `0` au minimum, pour rester résilient à un éventuel décalage entre le compteur et le contenu réellement stocké.
  ///
  /// Recalculer ce total en parcourant l'intégralité des contenus stockés à chaque écriture serait coûteux sur un gros
  /// volume de contenus. Ce compteur incrémental évite ce recalcul complet.
  ///
  /// - [deltaBytes] : variation du poids, en octets.
  Future<void> adjustCurrentSizeInBytes(int deltaBytes);

  /// Réinitialise `currentSizeInBytes` à `0`.
  ///
  /// Utilisé par `ClearContentsUsecase`, qui supprime l'intégralité des contenus stockés : recalculer un delta n'aurait
  /// pas de sens ici, la nouvelle valeur connue avec certitude est `0`.
  Future<void> resetCurrentSizeInBytes();
}
