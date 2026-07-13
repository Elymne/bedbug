# Scores de contenu — travail restant

Suivi des chantiers liés au système de score des `Content` (voir `ContentOrigin`,
`Content.broadcastScore`, `Content.survivalScore`).

## Fait

- `survivalScore` : `RecalculateSurvivalScoresUsecase` (décroissance par demi-vie selon
  `ContentOrigin`, bonus de `bounce` plafonné, `owned` fixe à `1.0`). Testé en unitaire
  (`test/unit/recalculate_survival_scores_usecase_test.dart`).

## À faire

### `broadcastScore` — priorité de diffusion BLE/WIFI

Usecase de recalcul du score de probabilité qu'un contenu soit envoyé en priorité via
BLE/WIFI. Règles encore à définir (par analogie avec `survivalScore`, mais les facteurs
ne sont pas forcément les mêmes — un contenu vieux mais jamais diffusé pourrait rester
prioritaire à l'envoi même s'il est peu prioritaire à la conservation).

### Score d'ordre d'affichage (priorité UI)

Nouveau score à créer : détermine l'ordre d'affichage des contenus dans la liste
(page d'accueil). Distinct de `broadcastScore` et `survivalScore` — reste à définir
quels facteurs y entrent (fraîcheur, origin, interactions utilisateur, etc.) et si ce
score est recalculé périodiquement comme les deux autres ou calculé à la volée au tri.

### Usecase de calcul du poids de stockage total

Nouveau usecase qui additionne `sizeInBytes` de tous les contents (et plus tard des
messages, si cette feature voit le jour) pour connaître l'espace total pris sur
l'appareil. Sert de brique de base à la future limite de stockage définie dans
`UserSettings` (champ à ajouter, ex. `maxStorageBytes`), qui elle-même s'appuiera sur
`survivalScore` pour décider quoi supprimer en priorité une fois la limite dépassée.

À voir : comment optimiser ce calcul s'il tourne sur un volume important de contenus
(éviter de tout recharger en mémoire à chaque appel — cache incrémental ? valeur
maintenue à jour à chaque écriture plutôt que recalculée entièrement ?).
