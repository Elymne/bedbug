# L'échange de contenus, de A à Z

Ce document raconte ce qui se passe réellement quand deux téléphones BedBug se croisent. Il se lit d'une traite. Chaque
partie renvoie vers un document plus détaillé, à lire seulement si tu veux creuser ce scope.

| Scope | Question | Document |
| ---------------- | ----------------------------------------------------- | ------------------------------------------ |
| Android | Pourquoi ça tourne quand l'app est fermée ? | [01-android.md](01-android.md) |
| Découverte | Comment deux téléphones se trouvent-ils ? | [02-decouverte.md](02-decouverte.md) |
| Connexion | Comment passent les octets, et à quelle vitesse ? | [03-connexion.md](03-connexion.md) |
| Session | Dans quel ordre parlent les téléphones ? | [04-session.md](04-session.md) |
| Contenus | Qu'est-ce qui est choisi, envoyé, accepté, refusé ? | [05-contenus.md](05-contenus.md) |
| Tests et pannes | Comment vérifier que ça marche, et comprendre un échec ? | [06-tests-et-pannes.md](06-tests-et-pannes.md) |

## L'idée en une phrase

Il n'y a aucun serveur : quand deux téléphones sont proches, chacun propose la liste de ce qu'il a, chacun choisit ce
qui l'intéresse, ils s'envoient les contenus choisis, puis ils se quittent.

## Le système en quatre couches

```text
  ┌────────────────────────────────────────────────────────────────┐
  │ Contenus    Que proposer ? Que choisir ? Que garder ?            │  Dart, use cases
  ├────────────────────────────────────────────────────────────────┤
  │ Session     Dans quel ordre parler ? Que faire si ça coupe ?     │  Dart, ExchangeSession
  ├────────────────────────────────────────────────────────────────┤
  │ Pont        Comment Dart et Kotlin se parlent-ils ?              │  canaux Flutter
  ├────────────────────────────────────────────────────────────────┤
  │ Radio       Trouver un téléphone, ouvrir un tuyau d'octets       │  Kotlin
  └────────────────────────────────────────────────────────────────┘
```

Une règle à retenir : **Kotlin ne comprend rien à ce qu'il transporte**. Il trouve des téléphones et déplace des octets.
Tout ce qui ressemble à une décision (quoi envoyer, quoi accepter) est en Dart.

## Le film complet : Alice croise Bob

### 1. Alice active l'échange

Alice coche la case de l'onglet Échange (`ExchangeScreen`).

1. `PassiveExchangeNotifier.setEnabled` appelle `StartPeerLinkUsecase`.
2. Le use case demande les permissions Bluetooth, puis demande à Android de démarrer.
3. `ExchangeService` démarre : la notification permanente apparaît. C'est elle qui donne à Android le droit de garder
   l'app en vie.
4. Le service crée `ExchangeRadio`, qui ouvre un serveur L2CAP et lance la découverte.
5. Le choix est enregistré dans les réglages : l'échange reprendra tout seul au prochain lancement.

L'icône Bluetooth du menu se met à trembler. Alice ferme l'app : l'écran disparaît, mais le service et le code Dart
continuent de tourner. Voir [01-android.md](01-android.md).

### 2. Les deux téléphones se trouvent

Le téléphone d'Alice diffuse en continu une petite annonce : « je suis un BedBug, mon identifiant temporaire est
`a1b2c3d4`, mon canal est le 137 ». Il écoute aussi les annonces des autres, en continu et en basse consommation : c'est la
puce Bluetooth qui filtre, et elle ne réveille le téléphone que si elle voit un BedBug.

Bob fait la même chose. L'un entend l'autre en quelques secondes, même écran éteint.

Pour éviter que les deux se connectent en même temps, **c'est toujours celui qui a le plus petit identifiant qui
appelle**. L'autre attend. Disons que c'est Alice. Voir [02-decouverte.md](02-decouverte.md).

### 3. Le tuyau s'ouvre

1. Les deux coupent annonce et scan : la puce Bluetooth partage sa radio, et les garder diviserait le débit par deux.
2. Alice ouvre un canal L2CAP vers Bob. C'est un tuyau d'octets, comme un socket.
3. Alice ouvre aussi une connexion GATT, qui ne transporte rien : elle sert uniquement à demander un lien plus rapide.
4. Kotlin prévient Dart par l'événement `connected`.
5. `PassiveExchangeNotifier` crée une `ExchangeSession`.

Voir [03-connexion.md](03-connexion.md).

### 4. La conversation

Les deux téléphones ont exactement le même rôle, et chacun envoie la même suite de messages, appelés trames :

```text
Alice                                   Bob
  HELLO   « je parle la version 1 »       HELLO
  OFFER   « voici ce que j'ai »           OFFER
  REQUEST « je veux ceux-là »             REQUEST
  DATA    « voici ce que tu as demandé »  DATA
  DONE    « bien reçu »                   DONE
```

Les deux sens se croisent en même temps : Alice n'attend pas d'avoir tout envoyé pour lire ce que Bob lui envoie. Si une
trame arrive dans le mauvais ordre, l'échange s'arrête. Voir [04-session.md](04-session.md).

### 5. Ce qui est échangé

- **OFFER** : Alice liste jusqu'à 50 contenus, 35 parmi les plus prioritaires et 15 au hasard. Ce ne sont que des
  identifiants et des tailles, pas les contenus.
- **REQUEST** : Bob retire ce qu'il possède déjà ou a déjà vu, puis tire au hasard dans le reste, jusqu'à 30 contenus ou
  200 Ko. C'est toujours **celui qui reçoit qui choisit**.
- **DATA** : Alice envoie les contenus demandés, leurs réactions et les signatures de leurs auteurs.
- **Import** : Bob vérifie tout, car tout ce qui vient d'un pair est falsifiable. Il refuse ce qu'il n'a pas demandé et
  ce qui dépasse les limites, puis enregistre le reste dans sa base.

Voir [05-contenus.md](05-contenus.md).

### 6. La fin

1. Chacun confirme la réussite à Kotlin, et Bob accuse réception avec DONE.
2. La connexion se ferme.
3. `PassiveExchangeNotifier` recalcule les scores et met à jour les compteurs de l'onglet Échange.
4. Annonce et scan reprennent.
5. L'initiateur (Alice) attend 10 minutes avant de recontacter Bob. Si l'échange a échoué, seulement 30 secondes.

Les contenus reçus sont déjà en base, mais la home ne le sait pas : Bob les voit en tirant son fil vers le bas.

### 7. Et avec plus de deux téléphones ?

Un contenu se propage de proche en proche, comme une rumeur. Le même contenu peut arriver par plusieurs chemins, mais il
n'existe qu'une fois sur chaque téléphone, car il est reconnu par son identifiant. Tout ce qui a été reçu est mémorisé
30 jours dans `seen_contents`, ce qui empêche aussi un contenu supprimé de revenir.

## Où est le code

```text
android/.../bedbug/exchange/      la radio, en Kotlin
lib/application/exchange/         la session, le notifier, les compteurs
lib/application/screens/exchange/ la page de l'onglet Échange
lib/features/exchange/            trames, transport, offre, sélection, lot, import
lib/features/content/             contenus, réactions, scores, « déjà vus »
```

## Vocabulaire

| Mot | Sens |
| ------------------- | -------------------------------------------------------------------------------- |
| Pair | L'autre téléphone |
| Annonce BLE | Petit message diffusé en continu, 31 octets au maximum |
| Scan | Écouter les annonces autour de soi |
| L2CAP | Canal d'octets entre deux appareils, comparable à un socket TCP |
| PSM | Numéro d'un canal L2CAP, comparable à un port réseau |
| GATT | L'autre façon de parler en BLE, par petites valeurs lues et écrites |
| Trame | Un message de notre protocole : type, longueur, charge utile |
| Offre, demande, lot | Ce que je propose, ce que je veux, ce que je t'envoie |
| Moteur Flutter | Ce qui exécute le code Dart, indépendamment de l'écran |
| Service de premier plan | Code sans écran qu'Android laisse tourner s'il affiche une notification |
| Identifiant éphémère | Identifiant aléatoire annoncé par un téléphone, remplacé toutes les 15 minutes |
