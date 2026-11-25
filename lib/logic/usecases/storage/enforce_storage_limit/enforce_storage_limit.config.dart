/// Nombre de contenus candidats lus à chaque tour de nettoyage.
///
/// Le poids réel n'est remesuré qu'entre deux tours : un tour assez grand évite de multiplier les mesures, assez
/// petit pour ne pas lire tout le stockage quand il ne dépasse que de peu.
const int storageCleanupBatchSize = 100;

/// Nombre maximal de tours de nettoyage par appel.
///
/// Garde-fou : chaque tour supprime au moins un contenu, mais un poids qui ne baisserait pas (données qui ne sont pas
/// des contenus) ne doit pas faire tourner le nettoyage indéfiniment. Le prochain appel reprend où celui-ci s'arrête.
const int maxStorageCleanupRounds = 20;
