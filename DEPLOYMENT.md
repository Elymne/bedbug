# Déploiement sur le Play Store

Ce guide décrit la mise en place, une seule fois, de la publication automatique des betas de bedbug sur le Play Store,
puis le cycle de publication au quotidien.

**Principe :**
- release-please tient à jour une PR de release sur `main` (`release-please-config.json`, en mode beta).
- Merger cette PR crée le tag (`v0.1.0-beta.1`, `v0.1.0-beta.2`…) et lance `.github/workflows/deploy_beta.yml`, qui
  construit l'app et l'envoie sur une piste de test du Play Store.
- Le nom de version vu par les testeurs vient du tag ; le numéro de build (`versionCode`) est calculé à partir de
  l'heure, il augmente donc à chaque envoi sans faire grimper le nom vu par les utilisateurs.
- Une beta validée est promue en production depuis la Play Console, sans rebuild.

Les commandes sont écrites pour Git Bash sous Windows ; elles s'adaptent directement à macOS ou Linux.

## 1. Créer la clé de signature (une seule fois, à vie)

`keytool` est fourni avec le JDK, par exemple celui d'Android Studio
(`C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe`).

```sh
mkdir -p ~/keys
"/c/Program Files/Android/Android Studio/jbr/bin/keytool.exe" -genkey -v \
  -keystore ~/keys/bedbug-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

- `keytool` demande un **mot de passe pour le keystore**, puis quelques informations (nom, ville…), et éventuellement
  un **mot de passe pour la clé** (sinon, c'est le même que celui du keystore).
- **Noter les deux mots de passe et l'alias (`upload`)** dans un gestionnaire de mots de passe.
- **Sauvegarder `bedbug-upload.jks` hors de l'ordinateur.** Ne jamais le mettre dans le dépôt (les fichiers `.jks`
  sont ignorés par git, mais autant le garder ailleurs).

## 2. Configurer la signature en local

Créer `android/key.properties` (ignoré par git) :

```properties
storeFile=C:/Users/<utilisateur>/keys/bedbug-upload.jks
storePassword=MOT_DE_PASSE_KEYSTORE
keyAlias=upload
keyPassword=MOT_DE_PASSE_CLE
```

Utiliser des `/` dans le chemin, même sous Windows. Sans ce fichier, la version release est signée avec la clé de
debug : `flutter run --release` fonctionne toujours, mais le Play Store refusera le fichier.

## 3. Construire le premier `.aab` en local

```sh
flutter build appbundle --release --build-name=0.0.0-beta.0 --build-number=1 --dart-define=ENV=preproduction
```

Le fichier produit : `build/app/outputs/bundle/release/app-release.aab`.

Vérifier qu'il est signé avec la bonne clé, et non avec celle de debug :

```sh
"/c/Program Files/Android/Android Studio/jbr/bin/keytool.exe" -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

Le propriétaire affiché doit être celui saisi à l'étape 1, et non `CN=Android Debug`.

## 4. Premier envoi à la main dans la Play Console

Google refuse en général les envois par l'API tant qu'aucun build n'a été envoyé à la main.

1. Ouvrir l'app `fr.bedbug` → **Tester et publier → Tests → Tests internes** (ou **Tests fermés**, selon la piste à
   laquelle la liste de testeurs est rattachée).
2. **Créer une release.** Accepter la **signature gérée par Google Play** (Play App Signing) : Google garde la clé
   finale, la clé de l'étape 1 ne sert plus qu'à envoyer les builds.
3. Envoyer `app-release.aab`, nommer la release (`0.0.0-beta.0`), puis **Enregistrer → Vérifier → Déployer**.
4. Dans l'onglet **Testeurs**, cocher la liste de testeurs et copier le lien d'inscription : chaque testeur doit
   l'ouvrir pour accepter de tester.

Ce premier build a le numéro 1 ; ceux du workflow sont bien plus grands (calculés à partir de l'heure), il n'y a donc
jamais de conflit.

## 5. Créer le compte de service (pour que GitHub publie)

**Google Cloud** (console.cloud.google.com) :

1. Créer un projet, par exemple `bedbug-publisher`.
2. **API et services → Bibliothèque** : activer **Google Play Android Developer API**.
3. **IAM et administration → Comptes de service → Créer** : par exemple `github-publisher`, sans rôle Cloud.
4. Ouvrir le compte → **Clés → Ajouter une clé → JSON**. Le fichier `.json` téléchargé est un secret : le garder
   comme la clé de signature.

**Play Console** :

1. **Utilisateurs et autorisations → Inviter des utilisateurs** : coller l'e-mail du compte de service
   (`github-publisher@….iam.gserviceaccount.com`).
2. **Autorisations de l'application** : ajouter `fr.bedbug` et cocher au minimum **Publier des versions dans des canaux
   de test** (et la production, pour automatiser la prod plus tard).
3. Envoyer l'invitation. Rien à accepter : le compte de service devient actif tout seul, parfois après quelques
   minutes.

## 6. Ajouter les secrets GitHub

Convertir la clé en base64 :

```sh
base64 -w 0 ~/keys/bedbug-upload.jks > ~/keys/bedbug-upload.b64
```

Dans le dépôt GitHub : **Settings → Secrets and variables → Actions → New repository secret**.

| Secret                      | Valeur                                                        |
| --------------------------- | ------------------------------------------------------------- |
| `ANDROID_KEYSTORE_BASE64`   | le contenu de `bedbug-upload.b64` (une seule longue ligne)    |
| `ANDROID_KEYSTORE_PASSWORD` | le mot de passe du keystore                                   |
| `ANDROID_KEY_ALIAS`         | `upload`                                                      |
| `ANDROID_KEY_PASSWORD`      | le mot de passe de la clé                                     |
| `PLAY_SERVICE_ACCOUNT_JSON` | le contenu **complet** du fichier `.json` du compte de service |

Supprimer ensuite `bedbug-upload.b64`, qui ne sert plus.

## 7. Régler les permissions de GitHub Actions

**Settings → Actions → General → Workflow permissions** :

- **Read and write permissions** ;
- cocher **Allow GitHub Actions to create and approve pull requests** (sans quoi release-please ne peut pas ouvrir sa
  PR).

Une PR ouverte avec le jeton par défaut de GitHub Actions ne déclenche pas la CI : si `main` exige que la CI passe avant
un merge, la PR de release restera bloquée. Il faut alors donner à release-please un jeton personnel (PAT).

## 8. Vérifier les réglages de `deploy_beta.yml`

En haut du workflow :

- `PLAY_TRACK` : `internal` pour le test interne, `alpha` pour le test fermé.
- `RELEASE_STATUS` : `completed`. Si l'envoi échoue avec « Only releases with status draft may be created on draft
  app », passer à `draft` : tant que l'app n'a jamais été publiée, Google n'accepte que des brouillons, à terminer à la
  main dans la console.
- `BUILD_ENV` : configuration embarquée dans l'app (`assets/config/<env>.json`), `preproduction` pour les betas.

## 9. Publier au quotidien

1. Merger les PR sur `main` avec des titres Conventional Commits (`feat: …`, `fix: …`), vérifiés par la CI.
2. release-please ouvre ou met à jour la PR **chore(main): release 0.x.y-beta.N**, avec le changelog.
3. Merger cette PR : le tag est créé, et la beta part sur le Play Store (suivi dans l'onglet **Actions**).
4. Les testeurs reçoivent la mise à jour par le Play Store.

En secours, un tag de beta posé à la main lance le même déploiement :

```sh
git tag v0.1.0-beta.1 && git push origin v0.1.0-beta.1
```

**Version finale** : pousser un commit dont le message contient `Release-As: 0.1.0`. release-please propose alors
`0.1.0` ; en attendant un workflow de production, promouvoir la dernière beta en production depuis la Play Console.

## Erreurs fréquentes

| Message                                                    | Cause                                                                                   |
| ---------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| `Package not found: fr.bedbug`                             | Aucun envoi manuel (étape 4), ou le compte de service n'a pas accès à l'app (étape 5).  |
| `The caller does not have permission`                      | Autorisation de publication manquante, ou invitation pas encore active : patienter.      |
| `APK specifies a version code that has already been used`  | Un build avec ce numéro existe déjà (ne devrait pas arriver avec le calcul par l'heure). |
| `Only releases with status draft…`                         | Voir l'étape 8.                                                                         |
| Envoi refusé pour une signature différente                 | L'`.aab` n'est pas signé avec la clé enregistrée chez Google : vérifier les secrets.    |
| La PR de release n'apparaît pas                            | Voir l'étape 7.                                                                         |
