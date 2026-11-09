import 'dart:io';

/// Chemin de la clé d'envoi (upload key), relatif à la racine du projet.
///
/// Partagé par les scripts qui la créent et qui l'envoient à GitHub, pour qu'ils ne puissent pas viser deux fichiers
/// différents. Le dossier `.key/` est ignoré par git.
const uploadKeystorePath = '.key/bedbug-upload.jks';

/// Alias de la clé dans le keystore, le même que `KEY_ALIAS` dans `.github/workflows/deploy_beta.yml`.
const uploadKeyAlias = 'upload';

/// Cherche l'exécutable `keytool`, fourni avec tout JDK.
///
/// Un développeur Flutter n'a pas forcément de JDK dans son PATH, mais a presque toujours Android Studio, qui en
/// embarque un : on essaie donc `JAVA_HOME`, puis le JDK d'Android Studio à son emplacement par défaut, et enfin le
/// PATH. Retourne `null` si aucun n'est trouvé.
String? findKeytool() {
  final executable = Platform.isWindows ? 'keytool.exe' : 'keytool';
  final javaHome = Platform.environment['JAVA_HOME'];

  final candidates = [
    if (javaHome != null) '$javaHome/bin/$executable',
    if (Platform.isWindows) 'C:/Program Files/Android/Android Studio/jbr/bin/$executable',
    if (Platform.isMacOS) '/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/$executable',
    if (Platform.isLinux) '/opt/android-studio/jbr/bin/$executable',
  ];

  for (final candidate in candidates) {
    if (File(candidate).existsSync()) {
      return candidate;
    }
  }

  // Dernier recours : keytool dans le PATH.
  final lookup = Process.runSync(Platform.isWindows ? 'where' : 'which', [executable]);
  if (lookup.exitCode != 0) {
    return null;
  }

  return (lookup.stdout as String).split('\n').first.trim();
}
