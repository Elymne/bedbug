import 'dart:io';

/// Lance les vérifications de la CI, en local comme sur GitHub Actions.
///
/// Un seul script Dart remplace les anciens `ci-checker.sh` et `ci-checker.ps1` : il tourne à l'identique sous
/// Windows, macOS et Linux, et la CI exécute le même code que le développeur, ce qui empêche les deux de diverger.
/// En local, il corrige le code avant de le vérifier ; en CI (`--ci`), il se contente de vérifier.
///
/// - [arguments] : `--ci` pour le mode CI, rien pour le mode local.
Future<void> main(List<String> arguments) async {
  final isCiMode = arguments.contains('--ci');

  // Le script vit dans tool/ : on se place à la racine du projet, d'où qu'il soit lancé.
  Directory.current = File.fromUri(Platform.script).parent.parent;

  final steps = [
    ('📦 Install dependencies', ['flutter', 'pub', 'get']),
    if (!isCiMode) ('🔧 Auto-fix analyzer issues', ['dart', 'fix', '--apply']),
    if (!isCiMode) ('🎨 Auto-format code', ['dart', 'format', 'lib/', 'test/', 'integration_test/', 'tool/']),
    ('🔍 Analyze code', ['flutter', 'analyze', '--fatal-infos', '--fatal-warnings']),
    if (isCiMode)
      (
        '🎨 Check formatting',
        ['dart', 'format', '--set-exit-if-changed', 'lib/', 'test/', 'integration_test/', 'tool/'],
      ),
    // Tous les tests de `test/` : unitaires, d'intégration et widgets. Le smoke test (`integration_test/`) demande un
    // vrai téléphone : il se lance à la main.
    ('🧪 Run all tests', ['flutter', 'test']),
  ];

  for (final (label, command) in steps) {
    stdout.writeln(label);

    // Sous Windows, flutter et dart sont des .bat : il faut passer par le shell pour les trouver.
    final process = await Process.start(
      command.first,
      command.sublist(1),
      mode: ProcessStartMode.inheritStdio,
      runInShell: Platform.isWindows,
    );

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      stderr.writeln('❌ $label failed (exit code $exitCode)');
      exit(exitCode);
    }
  }

  stdout.writeln('✅ CI checks passed');
}
