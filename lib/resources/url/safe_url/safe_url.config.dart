/// Longueur maximale, en caractères, d'une URL acceptée.
///
/// Largement assez pour l'URL d'un média ou d'une page ; au-delà, c'est
/// presque toujours une URL fabriquée pour piéger un analyseur.
const int maxSafeUrlLength = 2048;

/// Longueur maximale, en caractères, d'un nom de domaine (RFC 1035).
const int maxHostNameLength = 253;
