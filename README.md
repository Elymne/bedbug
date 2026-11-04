# BedBug

Projet BedBug, une application de communication locale (wifi/ble) open-source.
Pensé comme un réseau social local. La transmission de messages et contenus se fait d'appareils à appareils.

## Développement assisté par IA

Ce projet est développé en grande partie avec l'aide de l'IA ([Claude Code](https://claude.com/claude-code)).
Les règles d'architecture, de structure et de style suivies par l'IA sont décrites dans [`CLAUDE.md`](CLAUDE.md).

Si tu souhaites contribuer en codant à la main, tu dois respecter ces mêmes règles, afin que le code reste homogène
quelle que soit sa provenance.

## Commandes utiles

### Installer les packages

```sh
flutter pub get
```

> Sous Windows, si la commande échoue avec `Building with plugins requires symlink support`, activer le
> **Mode développeur** (`start ms-settings:developers`).

### Mettre à jour les traductions (l10n)

À lancer après chaque modification d'un fichier `.arb` dans `lib/application/l10n/`.
La configuration est lue depuis `l10n.yaml`, et les fichiers sont générés dans `lib/application/l10n/generated/`
(ne jamais les modifier à la main).

```sh
flutter gen-l10n
```

### Générer le code automatique (Hive)

À lancer après chaque modification d'un modèle annoté `@HiveType` / `@HiveField`. Génère les fichiers `*.g.dart`
et `lib/hive_registrar.g.dart`.

```sh
dart run build_runner build --delete-conflicting-outputs
```

Le générateur formate à 80 colonnes : reformater ensuite à 120 pour coller au style du projet.

```sh
dart format --line-length 120 lib/ test/
```

### Vérifier avant de pousser

Reproduit localement la CI (install, fix, format, analyse, tests) :

```sh
dart run tool/ci_check.dart         # corrige (fix, format) puis vérifie
dart run tool/ci_check.dart --ci    # vérifie sans rien modifier, comme la CI
```

### Mettre à jour la Public Suffix List

Télécharge la dernière version officielle dans `assets/data/public_suffix_list.dat`, après validation. Un workflow le
fait chaque lundi et ouvre une PR s'il y a du changement ; à lancer à la main avant une release si besoin :

```sh
dart run tool/update_public_suffix_list.dart
```

### Lancer les tests

Tous les tests de `test/` (unitaires, d'intégration et widgets) tournent dans la CI, à chaque PR :

```sh
flutter test                # tout
flutter test test/widget    # un seul jeu
```

Un smoke test parcourt l'app sur un vrai téléphone : premier lancement, ouverture de chaque page, publication d'un
contenu. Il ne vérifie pas le détail des pages, seulement qu'aucune ne plante, avec le vrai Hive, les vraies polices et le
vrai rendu. Ses données vivent dans un dossier à part, effacé à chaque lancement : celles de l'app ne sont pas touchées.
À lancer avant chaque version, téléphone Android branché :

```sh
flutter test integration_test/app_smoke_test.dart
```
