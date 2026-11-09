import 'dart:convert';
import 'dart:io';

import 'src/keytool.dart';

/// Environnement GitHub qui détient les secrets de publication, celui de `.github/workflows/deploy_beta.yml`.
const _environment = 'play-store';

/// Références autorisées à utiliser l'environnement : `main` (déploiement lancé par release-please, ou build manuel)
/// et les tags de beta (déploiement de secours).
const _allowedRefs = [('main', 'branch'), ('v*-beta*', 'tag')];

/// Variable d'environnement qui transmet le mot de passe à `keytool`, pour ne jamais le passer en argument (visible
/// dans la liste des processus).
const _passwordVariable = 'BEDBUG_KEYSTORE_PASSWORD';

/// Configure GitHub pour que le workflow de déploiement publie sur le Play Store, sans aucune manipulation à la main.
///
/// Faire ces réglages dans l'interface de GitHub multiplie les occasions d'erreur (base64 mal copié, mauvais mot de
/// passe, secret au mauvais niveau) et laisse traîner des fichiers sensibles sur le disque. Ce script :
/// - vérifie le mot de passe de la clé avant de l'envoyer, pour qu'une faute de frappe ne se découvre pas en CI ;
/// - range les secrets dans l'environnement `play-store`, accessible seulement depuis `main` et les tags de beta, et
///   non au niveau du dépôt, où n'importe quel workflow pourrait les lire ;
/// - encode la clé en mémoire, sans fichier intermédiaire ;
/// - règle les permissions de GitHub Actions : lecture seule par défaut (chaque workflow déclare ce dont il a besoin),
///   et droit de créer des PR, dont release-please a besoin ;
/// - supprime les anciens secrets du dépôt devenus inutiles.
///
/// Il peut être relancé sans risque, par exemple pour remplacer la clé du compte de service.
///
/// - [arguments] : `--service-account <fichier.json>` pour envoyer aussi la clé du compte de service Google.
Future<void> main(List<String> arguments) async {
  // Le script vit dans tool/ : on se place à la racine du projet, d'où qu'il soit lancé.
  Directory.current = File.fromUri(Platform.script).parent.parent;

  final serviceAccount = _readServiceAccount(arguments);

  final keystore = File(uploadKeystorePath);
  if (!keystore.existsSync()) {
    _fail('${keystore.path} not found: run dart run tool/generate_upload_key.dart first');
  }

  final keytool = findKeytool();
  if (keytool == null) {
    _fail('keytool not found: install Android Studio, or set JAVA_HOME, or add keytool to the PATH');
  }

  await _gh([
    'auth',
    'status',
  ], failure: 'GitHub CLI not ready: install it (winget install GitHub.cli), then gh auth login');

  final password = _askPassword();
  _checkKeystore(keytool, keystore, password);

  stdout.writeln('⚙️  Restricting GitHub Actions permissions (read-only by default, pull requests allowed)');
  await _gh([
    'api',
    '-X',
    'PUT',
    'repos/{owner}/{repo}/actions/permissions/workflow',
    '-f',
    'default_workflow_permissions=read',
    '-F',
    'can_approve_pull_request_reviews=true',
  ], failure: 'Could not update the GitHub Actions permissions');

  await _configureEnvironment();

  stdout.writeln('🔐 Sending secrets to the $_environment environment');
  await _setSecret('ANDROID_KEYSTORE_BASE64', base64Encode(keystore.readAsBytesSync()));
  await _setSecret('ANDROID_KEYSTORE_PASSWORD', password);
  if (serviceAccount != null) {
    await _setSecret('PLAY_SERVICE_ACCOUNT_JSON', serviceAccount);
  }

  await _removeRepositorySecrets(isServiceAccountSent: serviceAccount != null);

  stdout.writeln('✅ GitHub is ready to deploy');
  if (serviceAccount == null) {
    stdout.writeln('   The Play service account was not sent: rerun with --service-account <file.json> once created.');
    return;
  }
  stdout.writeln('   You can now delete the service account .json file from this computer.');
}

/// Lit le fichier du compte de service passé avec `--service-account`, ou retourne `null` s'il est absent.
///
/// Le contenu est contrôlé avant l'envoi : un mauvais fichier (clé OAuth, fichier tronqué) ne se verrait sinon qu'au
/// premier déploiement, par une erreur d'authentification peu parlante.
///
/// - [arguments] : arguments de la ligne de commande.
String? _readServiceAccount(List<String> arguments) {
  final index = arguments.indexOf('--service-account');
  if (index == -1) {
    return null;
  }
  if (index + 1 >= arguments.length) {
    _fail('--service-account expects the path of the service account .json file');
  }

  final file = File(arguments[index + 1]);
  if (!file.existsSync()) {
    _fail('${file.path} not found');
  }

  final content = file.readAsStringSync();
  try {
    final json = jsonDecode(content) as Map<String, dynamic>;
    if (json['type'] != 'service_account' || json['client_email'] == null || json['private_key'] == null) {
      _fail('${file.path} is not a service account key (expected "type": "service_account")');
    }
    stdout.writeln('👤 Service account: ${json['client_email']}');
  } on FormatException {
    _fail('${file.path} is not valid JSON');
  }

  return content;
}

/// Demande le mot de passe de la clé sans l'afficher.
///
/// Certains terminaux (Git Bash sous Windows notamment) ne permettent pas de masquer la saisie : on prévient alors
/// plutôt que d'échouer, la saisie restant locale.
String _askPassword() {
  stdout.write('🔑 Upload key password: ');
  var isEchoDisabled = false;
  try {
    stdin.echoMode = false;
    isEchoDisabled = true;
  } on StdinException {
    stdout.write('(this terminal cannot hide it) ');
  }

  try {
    final password = stdin.readLineSync(encoding: utf8) ?? '';
    if (password.isEmpty) {
      _fail('empty password');
    }
    return password;
  } finally {
    if (isEchoDisabled) {
      stdin.echoMode = true;
      stdout.writeln();
    }
  }
}

/// Vérifie que [password] ouvre [keystore], qu'il contient l'alias attendu et qu'il est au format PKCS12.
///
/// Le workflow utilise le même mot de passe pour le keystore et pour la clé, ce que garantit le format PKCS12 ; un
/// ancien keystore JKS pourrait avoir deux mots de passe différents et casserait le build en CI.
///
/// - [keytool] : chemin de l'exécutable `keytool`.
/// - [keystore] : fichier de la clé d'envoi.
/// - [password] : mot de passe saisi.
void _checkKeystore(String keytool, File keystore, String password) {
  final result = Process.runSync(
    keytool,
    ['-list', '-v', '-keystore', keystore.path, '-alias', uploadKeyAlias, '-storepass:env', _passwordVariable],
    environment: {_passwordVariable: password},
  );

  if (result.exitCode != 0) {
    _fail('wrong password, or no "$uploadKeyAlias" key in ${keystore.path}');
  }
  if (!(result.stdout as String).contains('PKCS12')) {
    _fail('${keystore.path} is not a PKCS12 keystore: its key password may differ from the keystore password');
  }

  stdout.writeln('✅ Password checked');
}

/// Crée l'environnement `play-store` (ou le met à jour) et n'y autorise que [_allowedRefs].
///
/// Sans cette restriction, un workflow lancé depuis n'importe quelle branche, y compris une branche de travail
/// modifiée, pourrait lire la clé de signature.
Future<void> _configureEnvironment() async {
  stdout.writeln('🛡️  Configuring the $_environment environment (main and beta tags only)');
  await _gh(
    ['api', '-X', 'PUT', 'repos/{owner}/{repo}/environments/$_environment', '--input', '-'],
    input: jsonEncode({
      'deployment_branch_policy': {'protected_branches': false, 'custom_branch_policies': true},
    }),
    failure: 'Could not create the $_environment environment',
  );

  final policiesJson = await _gh([
    'api',
    'repos/{owner}/{repo}/environments/$_environment/deployment-branch-policies',
  ], failure: 'Could not read the $_environment environment rules');
  final policies = (jsonDecode(policiesJson) as Map<String, dynamic>)['branch_policies'] as List<dynamic>;
  final existing = {for (final policy in policies.cast<Map<String, dynamic>>()) '${policy['type']}:${policy['name']}'};

  for (final (name, type) in _allowedRefs) {
    if (existing.contains('$type:$name')) {
      continue;
    }
    await _gh([
      'api',
      '-X',
      'POST',
      'repos/{owner}/{repo}/environments/$_environment/deployment-branch-policies',
      '-f',
      'name=$name',
      '-f',
      'type=$type',
    ], failure: 'Could not allow $type $name in the $_environment environment');
  }
}

/// Enregistre le secret [name] dans l'environnement `play-store`, en passant [value] par l'entrée standard pour qu'il
/// n'apparaisse jamais dans les arguments d'une commande.
///
/// - [name] : nom du secret, tel que le lit le workflow.
/// - [value] : valeur du secret.
Future<void> _setSecret(String name, String value) async {
  await _gh(['secret', 'set', name, '--env', _environment], input: value, failure: 'Could not set the $name secret');
  stdout.writeln('   $name');
}

/// Supprime les secrets de signature du niveau du dépôt, désormais rangés dans l'environnement.
///
/// Un secret de dépôt est lisible par tous les workflows : le laisser annulerait la restriction de l'environnement.
/// `ANDROID_KEY_ALIAS` et `ANDROID_KEY_PASSWORD` ne servent plus (alias fixe, mot de passe unique).
///
/// - [isServiceAccountSent] : `PLAY_SERVICE_ACCOUNT_JSON` n'est supprimé que s'il vient d'être rangé dans
///   l'environnement, pour ne pas casser le déploiement.
Future<void> _removeRepositorySecrets({required bool isServiceAccountSent}) async {
  final listJson = await _gh(['secret', 'list', '--json', 'name'], failure: 'Could not list the repository secrets');
  final names = (jsonDecode(listJson) as List<dynamic>).map((secret) => (secret as Map<String, dynamic>)['name']);

  final obsolete = [
    'ANDROID_KEYSTORE_BASE64',
    'ANDROID_KEYSTORE_PASSWORD',
    'ANDROID_KEY_ALIAS',
    'ANDROID_KEY_PASSWORD',
    if (isServiceAccountSent) 'PLAY_SERVICE_ACCOUNT_JSON',
  ];

  for (final name in obsolete.where(names.contains)) {
    await _gh(['secret', 'delete', name], failure: 'Could not delete the $name repository secret');
    stdout.writeln('🗑️  Removed repository secret $name');
  }

  if (!isServiceAccountSent && names.contains('PLAY_SERVICE_ACCOUNT_JSON')) {
    stdout.writeln(
      '⚠️  PLAY_SERVICE_ACCOUNT_JSON is still a repository secret: rerun with --service-account to move it.',
    );
  }
}

/// Lance la commande GitHub CLI `gh` avec [arguments] et retourne sa sortie, ou arrête le script avec [failure].
///
/// - [arguments] : arguments de `gh`.
/// - [input] : texte envoyé sur l'entrée standard (corps de requête, valeur de secret).
/// - [failure] : message affiché si la commande échoue.
Future<String> _gh(List<String> arguments, {String? input, required String failure}) async {
  final Process process;
  try {
    process = await Process.start('gh', arguments);
  } on ProcessException {
    _fail('GitHub CLI not found: install it (winget install GitHub.cli), then gh auth login');
  }

  if (input != null) {
    process.stdin.write(input);
  }
  await process.stdin.close();

  final output = process.stdout.transform(utf8.decoder).join();
  final errors = process.stderr.transform(utf8.decoder).join();
  if (await process.exitCode != 0) {
    _fail('$failure\n${await errors}');
  }

  return await output;
}

/// Affiche [message] comme une erreur et arrête le script.
///
/// - [message] : cause de l'arrêt.
Never _fail(String message) {
  stderr.writeln('❌ $message');
  exit(1);
}
