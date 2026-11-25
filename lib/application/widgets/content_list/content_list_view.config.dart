/// Nombre de contenus avant la fin de la liste à partir duquel la page suivante est demandée.
///
/// Demander la suite un peu avant la fin laisse le temps de la charger pendant que l'utilisateur lit les derniers
/// contenus : le défilement ne bute pas sur le loader.
const int contentListLoadMoreThreshold = 5;
