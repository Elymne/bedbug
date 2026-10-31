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

## Écouter par cycles

Scanner est ce qui consomme le plus. Le scan tourne donc par cycles : **10 secondes d'écoute, 50 secondes de pause**.
L'annonce, elle, reste permanente.

Il suffit qu'un téléphone écoute pendant que l'autre s'annonce. Comme l'annonce ne s'arrête jamais, deux téléphones se
trouvent en une minute au pire. La consommation réelle n'a pas encore été mesurée.

Le scan est filtré sur l'UUID BedBug : sans filtre, Android le coupe quand l'écran s'éteint.

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
durée. Pendant un échange, la découverte étant coupée, le nouvel identifiant sert à la reprise.

Conséquence : l'identifiant change plus vite que certains délais. Un pair au nouvel identifiant est vu comme inconnu et
peut être recontacté avant les 10 minutes. Ce n'est pas gênant : il n'y aura rien à transférer, et l'échange sera court.

## Un échange à la fois

Le premier arrivé réserve la radio (`isBusy`). Une connexion entrante pendant un échange est refusée, et la découverte
reste coupée jusqu'à la fermeture. Il est donc normal qu'un troisième téléphone attende son tour.
