/// Nom de la box Hive des contenus vus par l'utilisateur.
const String viewedContentBoxName = 'viewed_content';

/// Nom de l'ancienne box des contenus vus, qui stockait la date de vue en entier brut, sans modèle.
///
/// Gardé uniquement pour migrer ses entrées vers [viewedContentBoxName] au démarrage, puis la supprimer.
const String legacyViewedContentBoxName = 'viewed_contents';
