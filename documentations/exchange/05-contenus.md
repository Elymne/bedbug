# Contenus : ce qui est choisi, envoyé, accepté, refusé

Code : `lib/features/exchange/domain/usecases/`.

Quatre use cases, un par étape. Ils produisent et reçoivent des octets, encodés en JSON compressé par
`JsonZlibExchangeCodecGateway`.

```text
Alice                                         Bob
BuildExchangeOfferUsecase      ── OFFER ──►   SelectFromExchangeOfferUsecase
BuildExchangeBundleUsecase     ◄─ REQUEST ──
                               ── DATA ───►   ImportExchangeBundleUsecase
```

Et la même chose dans l'autre sens, en même temps.

## 1. L'offre

On ne pousse pas de contenus à l'aveugle : la bande passante est rare, et on ne sait pas ce que le pair possède.

L'offre liste au plus **50 contenus** :

- les **35** de plus fort `broadcastScore` ;
- **15** tirés au hasard dans le reste.

Sans cette part de hasard, l'offre proposerait toujours les mêmes contenus, et les autres ne circuleraient plus.

Pour chaque contenu, elle donne son identifiant, son poids, et un résumé de ses réactions (nombre, date de la plus
récente). Elle ne contient pas les contenus eux-mêmes.

## 2. La demande

C'est **celui qui reçoit qui choisit**, et au hasard : un pair ne peut pas imposer ce qui circule, et deux téléphones ne
repartent pas avec les mêmes contenus.

1. Sont écartés les contenus déjà possédés et ceux de `seen_contents`.
2. Le tirage est pondéré par la place dans l'offre : du poids 1 pour le premier à 0,2 pour le dernier. Les récents passent
   plus souvent, les autres passent quand même.
3. Il s'arrête au budget : **30 contenus** ou **200 Ko**. Un contenu trop lourd pour ce qui reste est sauté.
4. Pour les contenus déjà possédés, seules les réactions sont redemandées, si le pair en a de plus récentes (20 contenus
   au maximum).

## 3. Le lot

Il contient les contenus demandés, leurs réactions et la signature complète de leur auteur.

**Aucun identifiant d'auteur ne voyage.** Sans serveur, un identifiant ne prouve rien. Le pair déduit un identifiant local
de la signature : `peer-<empreinte>`. Deux contenus portant exactement la même signature se regroupent donc sur la même
page `s/pseudo`. Un contenu anonyme part sans signature.

## 4. L'import

Tout ce qui vient d'un pair est falsifiable : ce use case est la frontière où rien n'est cru sans être vérifié.

| Vérification | Si ça ne passe pas |
| --------------------------------------------------- | -------------------------- |
| Le contenu a été demandé | Refusé |
| Il n'est ni possédé, ni déjà vu | Refusé |
| Flair valide, nombre de médias correct | Refusé |
| Dessin dans ses limites | Refusé |
| Poids recalculé inférieur à 128 Ko | Refusé |
| Signature valide | Le contenu passe en anonyme |
| Réaction valide, et moins de 200 par contenu | Réaction refusée |

Les champs propres à l'appareil sont fixés ici : provenance publique, rebonds + 1 (bornés), dates ramenées à aujourd'hui
si elles sont dans le futur. Un refus n'empêche pas d'importer les suivants.

## Pourquoi un contenu n'existe qu'une fois

Un contenu est reconnu par son `id`, à trois niveaux :

1. **Au choix** : le receveur ne demande pas ce qu'il possède ou a déjà vu.
2. **À l'import** : ce qui n'a pas été demandé, ou qui est déjà possédé, est refusé.
3. **Après l'import** : tous les contenus reçus, même refusés, entrent dans `seen_contents` pour 30 jours.

La suppression d'un post l'y inscrit aussi : un pair qui en détient une copie ne peut pas le faire revenir. La suppression
reste locale : les copies déjà transmises ne peuvent pas être rappelées.

Passé 30 jours, un contenu supprimé pourrait revenir, s'il circule encore.

## Les réactions

Elles sont stockées à part et voyagent sans auteur. Leur identifiant en tient lieu : l'auteur réutilise le même quand il
modifie sa réaction. Seule la version la plus récente est gardée, et une réaction reçue ne remplace jamais celle de
l'utilisateur.

## Les scores

| Score | Rôle |
| --------------- | ------------------------------------ |
| `broadcastScore` | Priorité dans l'offre |
| `displayScore` | Ordre du fil d'accueil |
| `survivalScore` | Chances de survivre à un nettoyage |

Ils sont recalculés après chaque session, qu'elle ait réussi ou non. Un contenu arrive avec les scores du pair jusqu'à ce recalcul.

## La limite de stockage

Les échanges ajoutent des contenus sans intervention : il faut bien en retirer. La limite se règle dans Paramètres >
Stockage : 50, 100 (par défaut) ou 250 Mo, ou une valeur libre entre 1 et 1000 Mo.

`EnforceStorageLimitUsecase` tourne après chaque session, juste après le recalcul des scores, et aussitôt quand la limite
change. S'il y a dépassement :

1. Les contenus reçus partent du plus faible `survivalScore` au plus fort, le plus ancien d'abord à score égal, jusqu'à
   repasser sous la limite.
2. Leurs réactions et commentaires partent avec eux.
3. Ils entrent dans `seen_contents` : sinon, le prochain pair les renverrait aussitôt.

Tes propres contenus ne sont jamais supprimés, même s'ils dépassent la limite à eux seuls. Tous les contenus reçus partent
alors, et ceux qui arrivent ensuite sont retirés après chaque session.

La limite est une limite d'usage, pas de sécurité : un échange peut la dépasser de 200 Ko le temps du nettoyage. Elle est
bornée à 1000 Mo parce que toute la box `contents` est chargée en mémoire.

## Où c'est stocké

| Box Hive | Contenu |
| --------------- | ---------------------------------------------------- |
| `contents` | Les contenus ; `origin` distingue les tiens (`owned`) des reçus (`public`) |
| `reactions` | Les réactions |
| `seen_contents` | Identifiant → date de vue, 30 jours |
| `signatures` | Les signatures reçues |

Il n'y a pas de date de réception sur un contenu : son `createdAt` reste celui d'origine.

`Wrap` et `Keychain`, dans la feature `exchange`, préparent un futur chiffrement par sub. Ils ne sont pas encore branchés :
les contenus voyagent en clair.
