/// Nombre maximal de contenus proposés dans une offre.
///
/// Une offre ne transporte que des identifiants (environ 60 octets par contenu une fois compressée) : 50 contenus
/// tiennent en quelques kilo-octets, une fraction de seconde en BLE, tout en laissant au pair un vrai choix.
const int maxOfferedContents = 50;

/// Nombre de contenus de l'offre choisis par priorité de diffusion, le reste étant tiré au hasard.
///
/// Une offre uniquement faite des contenus les plus prioritaires proposerait toujours les mêmes : au-delà de
/// [maxOfferedContents] contenus, les autres ne circuleraient plus du tout.
const int priorityOfferedContents = 35;
