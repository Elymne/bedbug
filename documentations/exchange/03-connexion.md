# Connexion : comment passent les octets

Code : `ExchangeRadio.kt`, `PeerConnection.kt`, `LinkTuner.kt`, côté Dart `exchange_transport_gateway.dart`.

## Le tuyau

`ExchangeTransportGateway` est le contrat que voit Dart : un flux d'octets entrants, `send`, `confirmSuccess`, `close`.
Une instance correspond à une connexion. Le protocole ne sait pas ce qu'il y a derrière, ce qui permet de le tester en
mémoire sans radio.

L2CAP ne garantit pas de frontières de messages : un envoi peut arriver en plusieurs morceaux, et plusieurs envois en un
seul. C'est pour ça que nos trames portent leur longueur.

## Accélérer le lien

| Réglage | Effet mesuré ou attendu |
| ---------------------------- | ------------------------------------------ |
| Couper annonce et scan | Environ 16 → 31 Ko/s, mesuré en phase 0 |
| Priorité de connexion haute | Intervalle de connexion plus court |
| PHY 2M | Mode radio deux fois plus rapide |

L'API L2CAP ne permet pas de demander les deux derniers. `LinkTuner` ouvre donc une connexion GATT vers le même appareil,
qui ne transporte aucune donnée. Elle partage le lien radio du L2CAP : ses réglages lui profitent. L'attente est limitée
à 3 secondes, pour qu'un pair sans PHY 2M ne bloque pas l'échange.

Ces mesures viennent d'une seule paire de téléphones, à courte distance.

## Les threads

Android interdit de bloquer le thread principal, et Flutter impose de l'utiliser pour les canaux.

| Thread | Rôle |
| ----------------------- | ---------------------------------- |
| Principal | Découverte, canaux Flutter |
| Acceptation | Attend les connexions entrantes |
| Connexion | Le `connect` bloquant de l'initiateur |
| Lecture, un par connexion | Transmet les octets reçus à Dart |
| Écriture, un par connexion | Écrit les envois, dans l'ordre |

Lecture et écriture sont séparées parce que les deux téléphones envoient en même temps : sur un seul thread, chacun
attendrait d'avoir fini d'envoyer pour lire, et l'échange se figerait.

## La contre-pression

La réponse à `send` ne part vers Dart qu'une fois les octets acceptés par la radio. `ExchangeSession` attend cette
réponse avant le morceau suivant : elle envoie au rythme de la radio, sans remplir la mémoire.

## La fermeture

Fermer le socket débloque les threads de lecture et d'écriture, qui s'arrêtent d'eux-mêmes. `PeerConnection.close` ne
s'exécute qu'une fois. Elle ferme aussi la connexion GATT, prévient Dart par `closed`, libère la radio et relance la
découverte.

Le processeur est gardé éveillé pendant un échange (2 minutes au maximum), pour qu'il ne s'endorme pas écran éteint.

## Le repli GATT : reporté

Quelques téléphones gèrent mal L2CAP. Un repli ferait passer les octets par GATT, en petits messages, derrière le même
`ExchangeTransportGateway`. Il demande un serveur GATT, le découpage et le réassemblage des messages, et la gestion du
rythme d'envoi. Il est reporté jusqu'à ce qu'on rencontre un modèle réellement concerné.

Aujourd'hui, un téléphone dont le L2CAP échoue n'échange donc pas.
