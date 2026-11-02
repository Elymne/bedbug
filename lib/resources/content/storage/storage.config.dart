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

/// Nom de la box Hive de la configuration de stockage.
const String storageBoxName = 'storage';
