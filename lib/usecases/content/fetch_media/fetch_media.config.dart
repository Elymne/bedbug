/// Nombre maximal de redirections suivies avant d'abandonner.
///
/// Un hébergeur sérieux redirige une ou deux fois (vers son CDN) : au-delà,
/// c'est une boucle ou une chaîne fabriquée pour égarer les vérifications.
const int maxMediaRedirects = 5;

/// Taille maximale d'une image ou d'un gif téléchargé, en octets.
///
/// Borne la mémoire et les données consommées, quoi qu'annonce le serveur.
const int maxImageBytes = 15 * 1024 * 1024;
