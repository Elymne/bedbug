# Session : dans quel ordre parlent les téléphones

Code : `lib/application/exchange/exchange_session.dart`, `lib/features/exchange/`.

La session vit dans `application` parce qu'elle appelle les use cases d'échange : seule cette couche en a le droit.

## Le format d'une trame

```text
| type (1 octet) | longueur (4 octets) | charge utile (N octets) |
```

| Trame | Valeur | Taille maximale | Contenu |
| --------- | ------ | --------------- | ----------------------------- |
| `hello` | `0x01` | 64 octets | Version du protocole |
| `offer` | `0x02` | 64 Ko | Ce que je propose |
| `request` | `0x03` | 64 Ko | Ce que je veux |
| `data` | `0x04` | 1 Mo | Le lot demandé |
| `done` | `0x05` | 0 | Lot reçu et traité |
| `error` | `0x06` | 0 | J'abandonne l'échange |

La taille est vérifiée dès l'en-tête, avant de réserver la mémoire : un pair ne peut pas annoncer 4 Go pour saturer le
téléphone. La mise en octets est dans `BinaryExchangeFrameCodecGateway`, et la reconstruction des trames à partir des
morceaux reçus dans `BinaryExchangeFrameDecoderGateway`.

## Le déroulé

Les deux téléphones jouent le même rôle : il n'y a ni client ni serveur.

```text
HELLO → OFFER → REQUEST → DATA → DONE
```

Chaque trame reçue est traitée jusqu'au bout, réponse comprise, avant la suivante. Chaque sens suit donc strictement cet
ordre, et la session n'attend qu'un seul type de trame à la fois : tout le reste est une violation du protocole.

Ce traitement en série garantit aussi qu'un seul use case touche Hive à la fois.

La lecture, elle, ne s'arrête jamais : les trames sont mises en file pendant que la session envoie. C'est ce qui permet
aux deux lots de se croiser. Les lots partent par morceaux de 4 Ko.

## Quand la session se termine

| Cause | Résultat | Pair prévenu |
| --------------------------- | --------------------- | ------------ |
| `done` reçu | Succès | |
| Autre version du protocole | `incompatibleVersion` | Non |
| Trame incohérente | `protocolViolation` | Oui |
| Erreur locale (base, taille) | `localError` | Oui |
| Le pair envoie `error` | `peerError` | Non |
| Connexion perdue | `transportClosed` | Non |
| Pas de progrès, ou trop long | `timeout` | Non |
| L'utilisateur coupe l'échange | `cancelled` | Oui |

Deux limites de temps : **15 secondes sans progrès** et **90 secondes au total**. La seconde empêche un pair d'occuper la
radio en envoyant juste assez d'octets pour ne jamais être inactif.

## Une connexion perdue n'est pas toujours un échec

Une fois le lot du pair importé, tout ce que la rencontre pouvait apporter est acquis : une connexion perdue ou un silence
en attendant `done` ne sont plus des échecs. C'est même la fin normale quand le pair ferme juste après son propre accusé.

Le lot voyage d'un bloc : une connexion perdue pendant son transfert ne laisse aucun contenu partiel.

`confirmSuccess` est appelé dès l'import, avant `done`, tant que la connexion est encore ouverte.

## Après la session

`PassiveExchangeNotifier` recalcule les trois scores, puis met à jour `ExchangeStatsNotifier`, affiché sur l'onglet
Échange. Ces compteurs repartent de zéro au redémarrage de l'app.
