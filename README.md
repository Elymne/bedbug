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

## Déploiement sur le Play Store

Les betas partent toutes seules sur le Play Store : merger la PR de release ouverte par release-please sur `main` crée
un tag (`v0.1.0-beta.1`…) et lance `.github/workflows/deploy_beta.yml`, qui construit, signe et envoie l'app.

**La clé de signature** se crée une seule fois, sur l'ordinateur du mainteneur, et n'est jamais commitée. Elle est
envoyée à GitHub comme **secret** : une valeur chiffrée, rangée dans les paramètres du dépôt et non dans son code, que
personne ne peut relire. À chaque déploiement, le workflow la reconstitue dans un dossier temporaire, signe l'app, puis
l'efface. Les autres développeurs n'ont besoin ni de la clé ni de son mot de passe : en local, les builds release sont
signés avec la clé de debug.

### Mise en place (une seule fois)

**1. Créer la clé de signature**, sur ton ordinateur :

```sh
dart run tool/generate_upload_key.dart
```

Crée `.key/bedbug-upload.jks` (ignoré par git) et refuse d'écraser une clé existante. `keytool` demande un mot de passe
(un seul : il protège à la fois le fichier et la clé), puis ton identité. Ranger **le mot de passe et le `.jks`** dans
un gestionnaire de mots de passe : perdre la clé oblige à demander sa réinitialisation au support de Google.

**2. Créer le compte de service Google**, qui permet à GitHub de publier :

- Sur console.cloud.google.com : créer un projet (`bedbug-publisher`), activer **Google Play Android Developer API**
  (**API et services → Bibliothèque**), créer un compte de service sans rôle (**IAM et administration → Comptes de
  service**), puis lui ajouter une clé **JSON** (**Clés → Ajouter une clé**). Le `.json` téléchargé est un secret.
- Dans la Play Console : **Utilisateurs et autorisations → Inviter des utilisateurs**, coller l'e-mail du compte de
  service, ajouter l'app `fr.bedbug` avec le seul droit **Publier des versions dans des canaux de test**. Le compte
  devient actif tout seul, parfois après quelques minutes.

**3. Envoyer les secrets à GitHub**, avec [GitHub CLI](https://cli.github.com) :

```sh
winget install GitHub.cli
gh auth login
dart run tool/setup_github_deployment.dart --service-account <fichier.json>
```

Le script demande le mot de passe de la clé et le vérifie, puis :
- crée l'environnement GitHub `play-store`, utilisable seulement depuis `main` et les tags `v*-beta*` ;
- y range la clé, son mot de passe et le compte de service ;
- met les workflows en lecture seule par défaut et autorise release-please à ouvrir sa PR.

Il peut être relancé sans risque. Supprimer ensuite le `.json` (une nouvelle clé se recrée à tout moment).

**4. Construire le premier `.aab` sur GitHub.** Google exige que le premier envoi se fasse à la main. Le workflow
doit déjà être sur `main` pour apparaître dans l'onglet Actions. Onglet
**Actions → Deploy beta → Run workflow**, sur `main` : le workflow construit et signe le bundle sans l'envoyer.
Télécharger l'artefact `bedbug-0.0.0-beta.0` en bas du résumé du run (effacé au bout d'un jour).

**5. L'envoyer à la main dans la Play Console** : **Tester et publier → Tests → Tests internes → Créer une release**.
Accepter la **signature gérée par Google Play**, envoyer `app-release.aab`, puis **Enregistrer → Vérifier → Déployer**.
Dans l'onglet **Testeurs**, cocher la liste de testeurs et partager le lien d'inscription.

**6. Vérifier les réglages** en haut de `deploy_beta.yml` : `PLAY_TRACK` (`internal` pour le test interne, `alpha`
pour le test fermé) et `RELEASE_STATUS` (`completed`, ou `draft` tant que l'app n'a jamais été publiée si Google
répond « Only releases with status draft may be created on draft app »).

### Publier au quotidien

1. Merger les PR sur `main` avec des titres Conventional Commits (`feat: …`, `fix: …`), vérifiés par la CI.
2. release-please ouvre ou met à jour la PR **chore(main): release 0.x.y-beta.N**, avec le changelog.
3. Merger cette PR : la beta part sur le Play Store (suivi dans l'onglet **Actions**), et les testeurs la reçoivent.

En secours, un tag posé à la main lance le même déploiement : `git tag v0.1.0-beta.1 && git push origin v0.1.0-beta.1`.

**Version finale** : pousser un commit dont le message contient `Release-As: 0.1.0`, puis promouvoir la dernière beta
en production depuis la Play Console (pas encore de workflow de production).

### Sécurité

- Les secrets sont dans l'environnement `play-store` : un workflow lancé depuis une autre branche ne peut pas les lire.
- Les actions des workflows sont épinglées par SHA de commit ; Dependabot propose chaque mois leur mise à jour.
- Le workflow refuse d'envoyer un bundle signé avec la clé de debug.

### Erreurs fréquentes

| Message                                                   | Cause                                                                                 |
| --------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| `Signing secrets missing from the play-store environment` | L'étape 3 n'a pas été faite.                                                          |
| Le job refuse l'environnement `play-store`                | Workflow lancé depuis une autre branche que `main` ou un tag de beta.                 |
| `Package not found: fr.bedbug`                            | Aucun envoi manuel (étape 5), ou le compte de service n'a pas accès à l'app.          |
| `The caller does not have permission`                     | Droit de publication manquant, ou invitation pas encore active : patienter.           |
| `Only releases with status draft…`                        | Passer `RELEASE_STATUS` à `draft` (étape 6).                                          |
| Envoi refusé pour une signature différente                | Le `.aab` n'est pas signé avec la clé enregistrée chez Google : relancer l'étape 3.   |
| La PR de release n'apparaît pas                           | Relancer l'étape 3. Si `main` exige la CI, release-please a besoin d'un jeton (PAT).  |
