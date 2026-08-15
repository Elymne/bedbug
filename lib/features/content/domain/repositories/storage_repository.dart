import 'package:bedbug/features/content/domain/entities/storage.dart';

/// Taille maximale allouée par défaut aux contenus, en octets (500 Mo).
///
/// Valeur de repli tant qu'aucun réglage utilisateur ne permet encore de la
/// modifier.
const int defaultMaxStorageSizeInBytes = 500 * 1024 * 1024;

/// Contrat du repository gérant la configuration [Storage].
///
/// Ce repository gère un unique objet de configuration.
abstract class StorageRepository {
  /// Retourne la configuration de stockage persistée, ou `null` si jamais initialisée.
  Future<Storage?> getUnique(String id);

  /// Retourne le nombre d'entrées effectivement présentes dans le stockage
  /// sous-jacent, tous identifiants confondus.
  ///
  /// Sert uniquement à détecter une incohérence : ce repository ne devrait
  /// jamais contenir plus d'une entrée puisqu'il gère un singleton. Un
  /// résultat supérieur à `1` trahit un bug (écriture sous une mauvaise clé,
  /// migration ratée, etc.), à surveiller par les use cases qui lisent
  /// cette configuration.
  Future<int> countAll();

  /// Persiste une nouvelle configuration de stockage [entity].
  Future<Storage> addOne(Storage entity);

  /// Met à jour la configuration de stockage existante [entity].
  ///
  /// Lève une `DatasourceException` si la configuration n'existe pas.
  Future<Storage> updateOne(Storage entity);

  /// Ajoute [deltaBytes] (positif ou négatif) à `currentSizeInBytes`.
  ///
  /// Crée la configuration de stockage avec les valeurs par défaut si elle
  /// n'existe pas encore. Le résultat est toujours plafonné à `0` au
  /// minimum, pour rester résilient à un éventuel décalage entre le compteur
  /// et le contenu réellement stocké.
  ///
  /// Recalculer ce total en parcourant l'intégralité des contenus stockés à
  /// chaque écriture serait coûteux sur un gros volume de contenus. Ce
  /// compteur incrémental évite ce recalcul complet ; il est utilisé par
  /// `SaveContentUsecase` et `SeedContentsUsecase`.
  Future<void> adjustCurrentSizeInBytes(int deltaBytes);

  /// Réinitialise `currentSizeInBytes` à `0`.
  ///
  /// Utilisé par `ClearContentsUsecase`, qui supprime l'intégralité des
  /// contenus stockés : recalculer un delta n'aurait pas de sens ici, la
  /// nouvelle valeur connue avec certitude est `0`.
  Future<void> resetCurrentSizeInBytes();
}
