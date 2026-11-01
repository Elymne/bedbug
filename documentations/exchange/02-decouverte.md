# Découverte : comment deux téléphones se trouvent

Code : `BleDiscovery.kt` et `ExchangeRadio.kt`.

## S'annoncer

Une annonce BLE tient en 31 octets. L'UUID de service BedBug en prend déjà une bonne partie, donc l'information est
répartie en deux :

- **L'annonce** ne porte que l'UUID. Elle dit « je suis un BedBug », et les autres filtrent leur scan dessus.
- **La réponse au scan**, 31 octets de plus récupérés automatiquement, porte l'identifiant éphémère (4 octets) et le PSM,
  le numéro du canal L2CAP (2 octets).

La réponse au scan arrive parfois après l'annonce. Une annonce sans ces données est ignorée, et le résultat suivant les
portera.

## Écouter en continu

Le scan et l'annonce sont permanents. Il n'y a volontairement **aucun minuteur** : `Handler.postDelayed` s'arrête quand
le processeur dort, et un scan programmé ne démarrerait jamais écran éteint. Les premières versions scannaient 10 secondes
par minute, et un téléphone endormi pendant la pause restait sourd jusqu'à son réveil.

Le scan tourne en basse consommation et il est filtré sur l'UUID BedBug. Sans filtre, Android le coupe quand l'écran
s'éteint. Avec lui, c'est la puce Bluetooth qui écoute, et elle ne réveille le processeur que si elle voit un BedBug. Le
journal Android indique si le téléphone sait le faire (`Filtrage par la puce Bluetooth`).

Dès qu'un pair est vu, le processeur est maintenu éveillé jusqu'à la fin de l'échange. La consommation réelle n'a pas
encore été mesurée. Elle dépend surtout du nombre de BedBug autour : chacun réveille le téléphone quelques instants.

## Qui appelle qui

Quand deux téléphones se voient, s'ils se connectaient tous les deux, on aurait deux connexions croisées. La règle :
**seul le téléphone au plus petit identifiant se connecte**. L'autre l'attend sur son serveur L2CAP.

## Ne pas rappeler le même pair

`ExchangeRadio` garde une table `nextAttemptAt` : identifiant du pair → prochaine tentative autorisée.

| Situation | Délai |
| -------------------------------- | ------------ |
| Une tentative est lancée | 30 secondes |
| Dart confirme la réussite | 10 minutes |

Le délai de 30 secondes s'applique donc aussi à un échange coupé en route : il sera vite retenté.

Cette table n'existe que chez l'initiateur, et ça suffit : pour une même paire, c'est toujours lui qui appelle. Elle est
en mémoire, et vidée à l'arrêt de la radio.

## L'identifiant éphémère

Il est aléatoire et remplacé toutes les 15 minutes, pour qu'un observateur ne puisse pas suivre un téléphone dans la
durée. Pendant un échange, la découverte étant coupée, le nouvel identifiant sert à la reprise. Ce remplacement passe par
un minuteur : pendant une longue veille, il attend le réveil suivant.

Conséquence : l'identifiant change plus vite que certains délais. Un pair au nouvel identifiant est vu comme inconnu et
peut être recontacté avant les 10 minutes. Ce n'est pas gênant : il n'y aura rien à transférer, et l'échange sera court.

## Un échange à la fois

Le premier arrivé réserve la radio (`isBusy`). Une connexion entrante pendant un échange est refusée, et la découverte
reste coupée jusqu'à la fermeture. Il est donc normal qu'un troisième téléphone attende son tour.
