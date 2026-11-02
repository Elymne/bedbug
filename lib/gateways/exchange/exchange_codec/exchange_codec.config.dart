/// Version du format d'échange. À incrémenter à chaque changement incompatible.
const int exchangeFormatVersion = 1;

/// Taille maximale d'un message une fois décompressé, en octets.
///
/// Un message compressé de quelques kilo-octets peut se décompresser en plusieurs giga-octets (« zip bomb ») :
/// la décompression s'arrête net au-delà de cette taille, bien au-dessus d'un lot légitime.
const int maxDecompressedExchangeBytes = 4 * 1024 * 1024;

/// Nombre maximal de contenus proposés dans une offre.
///
/// Limite du protocole, partagée par les deux côtés de l'échange : celui qui construit l'offre et celui qui la lit.
/// Une offre ne transporte que des identifiants (environ 60 octets par contenu une fois compressée) : 50 contenus
/// tiennent en quelques kilo-octets, une fraction de seconde en BLE, tout en laissant au pair un vrai choix.
const int maxOfferedContents = 50;

/// Nombre maximal de contenus demandés en un échange.
///
/// Limite du protocole, partagée par celui qui fait la demande et celui qui y répond.
const int defaultMaxRequestedContents = 30;

/// Nombre maximal de contenus déjà possédés dont on redemande les réactions en un échange.
///
/// Limite du protocole, partagée par celui qui fait la demande et celui qui y répond.
const int maxReactionRefreshContents = 20;
