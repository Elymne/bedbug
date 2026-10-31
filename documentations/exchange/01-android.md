# Android : pourquoi ça tourne quand l'app est fermée

Code : `android/.../bedbug/exchange/` et `MainActivity.kt`.

## Le problème

Android tue une app en arrière-plan au bout de quelques minutes, et `FlutterActivity` détruit par défaut son moteur
Flutter avec l'écran. Pour échanger en permanence, il faut résoudre ces deux points.

## Le service de premier plan

`ExchangeService` est un service de premier plan de type `connectedDevice`. Android le tolère parce qu'il affiche une
notification permanente : l'utilisateur voit que l'app travaille, et peut l'arrêter avec le bouton de la notification.

Le service ne contient aucune logique : il garde le processus vivant et possède la `ExchangeRadio`.

## Le moteur partagé

Par défaut, l'écran crée son moteur Flutter et le détruit en se fermant. Un second moteur pour le service n'est pas
possible : deux moteurs, ce sont deux isolates Dart sur les mêmes fichiers Hive, ce qui peut les corrompre.

`SharedFlutterEngine` crée donc un moteur unique, gardé dans `FlutterEngineCache`. L'écran et le service l'utilisent tous
les deux : fermer l'app arrête seulement l'affichage.

## Le cycle de vie

| Moment | Ce qui se passe |
| ----------------------- | --------------------------------------------------------------------------------- |
| Ouverture de l'app | `MainActivity` demande le moteur partagé, qui lance `main()` |
| `main()` | Lit `PassiveExchangeNotifier`, qui reprend l'échange si le réglage est actif |
| Case cochée | Permissions, puis démarrage du service et de la radio, puis choix enregistré |
| Fermeture de l'app | L'écran disparaît ; le moteur, le service et le code Dart continuent |
| Réouverture | `MainActivity` se rattache au même moteur, rien ne redémarre |
| Case décochée | Session annulée, service arrêté, choix enregistré |
| Bouton « Arrêter » | `ExchangeService.onDestroy` ferme la radio et envoie `stopped` à Dart |
| Bluetooth coupé | Le serveur L2CAP échoue, le service s'arrête, Dart reçoit `stopped` |
| Android tue le processus | Le service est `START_STICKY` : Android le relance dès qu'il peut |

### Le cas de la relance par Android

Android recrée le service sans aucun écran. Le service recrée le moteur, qui relance `main()`. Comme aucun écran ne
s'affiche, aucun widget n'est construit : c'est pour ça que `main()` lit lui-même `passiveExchangeNotifierProvider`.
Sans cette ligne, personne n'écouterait les connexions.

Le notifier reprend alors sans demander de permissions, puisqu'aucun écran ne pourrait les afficher. Kotlin voit que la
radio tourne déjà et répond `started`.

Android peut aussi refuser de repasser le service au premier plan. Le service s'arrête alors proprement, et l'échange
reprendra à la prochaine ouverture de l'app.

## Les permissions

| Permission | Pourquoi |
| -------------------------------------------------------- | ------------------------------------------------------ |
| `BLUETOOTH_SCAN`, `BLUETOOTH_ADVERTISE`, `BLUETOOTH_CONNECT` | Android 12+. Le scan est déclaré `neverForLocation` |
| `BLUETOOTH`, `BLUETOOTH_ADMIN`, `ACCESS_FINE_LOCATION` | Android 10 et 11, où le scan BLE exige la localisation |
| `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_CONNECTED_DEVICE` | Le service de premier plan |
| `POST_NOTIFICATIONS` | Android 13+. Facultative : sans elle, le service tourne mais la notification ne s'affiche pas |
| `WAKE_LOCK` | Garder le processeur éveillé pendant un échange, écran éteint |

Les permissions se demandent depuis une activité : c'est la seule partie de l'échange qui vit dans `MainActivity`.

## Le pont avec Dart

Tout passe par `ExchangeChannels`, sur le thread principal comme Flutter l'exige.

`bedbug/exchange`, Dart appelle Kotlin :

| Méthode | Arguments | Réponse |
| --------- | ------------- | ---------------------------------------------------------------- |
| `start` | | `started`, `bluetoothOff`, `permissionDenied` ou `unavailable` |
| `stop` | | |
| `send` | `id`, `bytes` | Quand les octets sont partis, erreur si la connexion est fermée |
| `confirm` | `id` | Échange réussi : 10 minutes avant de recontacter ce pair |
| `close` | `id` | |

`bedbug/exchange/events`, Kotlin prévient Dart : `connected {id}`, `data {id, bytes}`, `closed {id}`, `stopped`.

`bedbug/exchange/permissions`, tenu par `MainActivity` : `request`, qui répond `true` si tout est accordé.

Côté Dart, `BlePeerLinkGateway` reçoit ces événements et `BleExchangeTransportGateway` représente une connexion.
