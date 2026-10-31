import 'package:bedbug/features/content/domain/entities/storage.dart';

/// Nombre d'octets dans un mégaoctet, l'unité des limites de stockage présentées à l'utilisateur.
const int bytesPerMegabyte = 1024 * 1024;

/// Taille maximale allouée par défaut aux contenus, en octets (100 Mo).
///
/// Toute la box des contenus vit en mémoire et son parcours suit chaque échange : une limite haute pèse sur le
/// téléphone. Un contenu pesant 128 Ko au maximum, 100 Mo en gardent déjà plusieurs milliers.
const int defaultMaxStorageSizeInBytes = 100 * bytesPerMegabyte;

/// Limites proposées d'office à l'utilisateur, en octets.
const List<int> storageLimitPresetsInBytes = [
  50 * bytesPerMegabyte,
  defaultMaxStorageSizeInBytes,
  250 * bytesPerMegabyte,
];

/// Plus petite limite qu'un utilisateur peut définir, en mégaoctets.
const int minStorageLimitInMegabytes = 1;

/// Plus grande limite qu'un utilisateur peut définir, en mégaoctets.
const int maxStorageLimitInMegabytes = 1000;

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
  /// `SaveContentUsecase` et `EnforceStorageLimitUsecase`.
  Future<void> adjustCurrentSizeInBytes(int deltaBytes);

  /// Réinitialise `currentSizeInBytes` à `0`.
  ///
  /// Utilisé par `ClearContentsUsecase`, qui supprime l'intégralité des
  /// contenus stockés : recalculer un delta n'aurait pas de sens ici, la
  /// nouvelle valeur connue avec certitude est `0`.
  Future<void> resetCurrentSizeInBytes();
}
