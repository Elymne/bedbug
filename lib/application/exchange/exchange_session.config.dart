/// Version du protocole de session, annoncée dans `ExchangeFrameType.hello`.
///
/// À incrémenter à chaque changement incompatible du déroulé ou des trames. Elle est distincte de la version du
/// format des messages, portée par le codec.
const int exchangeProtocolVersion = 1;

/// Taille maximale d'un envoi au transport, en octets.
///
/// Un lot est découpé pour que chaque morceau accepté prouve que l'échange avance : sans cela, un long envoi
/// ressemblerait à un silence du pair.
const int exchangeChunkBytes = 4 * 1024;

/// Durée sans aucun progrès, ni reçu ni envoyé, au bout de laquelle le pair est considéré comme perdu.
const Duration defaultExchangeInactivityTimeout = Duration(seconds: 15);

/// Durée maximale d'une session, quoi qu'il arrive.
///
/// Empêche un pair d'occuper la radio en envoyant juste assez d'octets pour ne jamais être inactif. Un lot honnête
/// passe en quelques secondes à 30 Ko/s ; cette durée couvre le maximum autorisé dans les deux sens.
const Duration defaultExchangeSessionTimeout = Duration(seconds: 90);
