# TODO

Suivi des chantiers du projet.

## Score de contenu

Chantiers liés au système de score des `Content` (voir `ContentOrigin`,
`Content.broadcastScore`, `Content.survivalScore`, `Content.displayScore`).

### Fait

- `survivalScore` : `RecalculateSurvivalScoresUsecase` (décroissance par demi-vie selon
  `ContentOrigin`, bonus de `bounce` plafonné, `owned` fixe à `1.0`). Testé
  (`test/integration/recalculate_survival_scores_usecase_test.dart`).

- `broadcastScore` : `RecalculateBroadcastScoresUsecase` (décroissance par demi-vie
  selon `ContentOrigin` — `broadcastHalfLifeDays`, bien plus courte que celle du
  `survivalScore` puisque la priorité de diffusion répond à une fenêtre de propagation
  qui se referme vite — pénalité de `bounce` plafonnée, `owned` fixe à `1.0`). Testé
  (`test/integration/recalculate_broadcast_scores_usecase_test.dart`).

- `displayScore` (priorité UI) : `RecalculateDisplayScoresUsecase` (décroissance par
  demi-vie selon `ContentOrigin` — `displayHalfLifeDays`, intermédiaire entre celle du
  `broadcastScore` et celle du `survivalScore` — bonus de `bounce` plafonné, `owned`
  fixe à `1.0`). `GetContentsUsecase` trie par défaut sur `displayScore` décroissant.
  Testé (`test/integration/recalculate_display_scores_usecase_test.dart`).

- Poids de stockage total : `Storage.currentSizeInBytes` (nouveau champ, entité
  singleton déjà existante avec `maxSizeInBytes` et `strategy`), maintenu de façon
  incrémentale plutôt que recalculé en parcourant tous les contents à chaque lecture :
  - `StorageRepository.adjustCurrentSizeInBytes`/`resetCurrentSizeInBytes` : signatures
    déclarées dans l'interface (domain), implémentées dans `HiveStorageRepository`
    (infra) en termes de `getUnique`/`addOne`/`updateOne`. Appelées par
    `SaveContentUsecase`, `SeedContentsUsecase` et `ClearContentsUsecase`.
  - `GetStorageUsecase` : lecture de la configuration de stockage (crée les valeurs
    par défaut si absente — `defaultMaxStorageSizeInBytes` = 500 Mo). Journalise un
    warning si `StorageRepository.countAll()` détecte plus d'une entrée persistée
    (ne devrait jamais arriver, ce repository gère un singleton).
  - `RecalculateStorageUsageUsecase` : recalcule le total en parcourant tous les
    contents et corrige `currentSizeInBytes` s'il a dérivé du compteur incrémental.
    À n'appeler que ponctuellement (ex. splashscreen), pas comme chemin de lecture
    principal — c'est un outil de réconciliation, pas la source de vérité au quotidien.

  Testé (`test/integration/recalculate_storage_usage_usecase_test.dart`).

  Reste à faire : `UserSettings.maxStorageBytes` (ou équivalent) pour permettre à
  l'utilisateur de configurer sa propre limite, et le usecase de nettoyage qui
  s'appuiera sur `survivalScore` + `Storage.strategy` pour décider quoi supprimer en
  priorité une fois `maxSizeInBytes` dépassé.

- `SaveContentUsecase` ne fait plus confiance au `sizeInBytes` fourni par l'appelant
  (un contenu reçu d'un pair pourrait mentir sur sa taille) : il détermine désormais
  lui-même le poids réel avant persistance, selon le type concret du contenu —
  `TextContent`/`LinkContent` : somme des octets UTF-8 de leurs champs texte ;
  `ImageContent` : taille réelle du fichier sur disque (`0` si le fichier est
  introuvable). Nouvelle méthode `Content.copyWithSizeInBytes` (comme
  `copyWithScores`) pour appliquer la correction sans connaître le sous-type concret.
  Au passage, corrigé un bug latent dans `create_screen.dart` qui écrivait les images
  à la racine du dossier de documents au lieu du sous-dossier `content_images` attendu
  par les écrans de lecture — le nom de ce sous-dossier est maintenant centralisé dans
  `contentImagesFolder` (`shared/config/content_image_storage.dart`) plutôt que
  dupliqué dans chaque fichier. Testé
  (`test/integration/save_content_usecase_test.dart`).
