import 'dart:io';

import 'src/keytool.dart';

/// Génère la clé d'envoi (upload key) qui signe les builds envoyés au Play Store.
///
/// Cette clé ne se crée qu'une fois : Google l'associe à l'app au premier envoi, et la perdre oblige à demander sa
/// réinitialisation au support de la Play Console. Le script fige donc ses paramètres (chemin, alias, algorithme)
/// pour qu'ils correspondent à ceux attendus par `tool/setup_github_deployment.dart` et par le workflow de déploiement,
/// et refuse d'écraser une clé existante. La clé est rangée dans `.key/`, ignoré par git.
///
/// `keytool` reste interactif : il demande lui-même le mot de passe et l'identité du propriétaire.
Future<void> main() async {
  // Le script vit dans tool/ : on se place à la racine du projet, d'où qu'il soit lancé.
  Directory.current = File.fromUri(Platform.script).parent.parent;

  final keystore = File(uploadKeystorePath);
  if (keystore.existsSync()) {
    stderr.writeln('❌ ${keystore.path} already exists: delete it first if you really want a new key');
    exit(1);
  }

  final keytool = findKeytool();
  if (keytool == null) {
    stderr.writeln('❌ keytool not found: install Android Studio, or set JAVA_HOME, or add keytool to the PATH');
    exit(1);
  }

  keystore.parent.createSync(recursive: true);

  stdout.writeln('🔑 Generating ${keystore.path} with $keytool');
  final process = await Process.start(keytool, [
    '-genkeypair',
    '-v',
    '-storetype',
    'PKCS12',
    '-keystore',
    keystore.path,
    '-keyalg',
    'RSA',
    '-keysize',
    '2048',
    '-validity',
    '10000',
    '-alias',
    uploadKeyAlias,
  ], mode: ProcessStartMode.inheritStdio);

  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    stderr.writeln('❌ keytool failed (exit code $exitCode)');
    exit(exitCode);
  }

  stdout.writeln('✅ Key generated in ${keystore.path} (alias: $uploadKeyAlias)');
  stdout.writeln('   Save the password in a password manager and back up the .jks outside this computer.');
  stdout.writeln('   Then send it to GitHub: dart run tool/setup_github_deployment.dart (see README.md).');
}
