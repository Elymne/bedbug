/// Nom de la box Hive des contenus déjà reçus ou supprimés.
const String seenContentBoxName = 'seen_content';

/// Nom de l'ancienne box des contenus déjà reçus ou supprimés, qui stockait la date en entier brut, sans modèle.
///
/// Gardé uniquement pour migrer ses entrées vers [seenContentBoxName] au démarrage, puis la supprimer.
const String legacySeenContentBoxName = 'seen_contents';
