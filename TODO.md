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

- Poids de stockage total : poids réel de la base SQLite, lu par
  `StorageRepository.getUsedSizeInBytes()` (`PRAGMA` page_count − freelist_count, × page_size).
  Plus de compteur tenu à la main, donc plus de dérive possible ni de réconciliation :
  `Storage` ne garde que la limite (`maxSizeInBytes`) et la stratégie. Le poids de chaque
  contenu (`size_in_bytes`) reste stocké pour l'offre d'échange, l'import et le choix des
  contenus à supprimer.

  Testé (`test/integration/storage_limit_usecases_test.dart`, `test/integration/app_database_test.dart`).

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
