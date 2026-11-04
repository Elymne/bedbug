import 'dart:convert';
import 'dart:io';

import 'package:bedbug/gateways/public_suffix/public_suffix/public_suffix.config.dart';

/// Remplace la Public Suffix List embarquée par la dernière version officielle.
///
/// La liste évolue (nouveaux suffixes, nouvelles plateformes d'hébergement) mais l'app l'embarque pour fonctionner
/// hors ligne : sans mise à jour, elle accepterait peu à peu des règles de confiance trop larges. Le script est
/// lancé chaque semaine par le workflow `update_public_suffix_list.yml`, et peut l'être à la main.
///
/// Une liste téléchargée n'écrase l'asset que si elle passe la validation : une page d'erreur embarquée à sa place
/// ferait refuser toutes les règles de domaine. En cas d'échec, l'asset reste intact et le script sort en erreur.
Future<void> main() async {
  // Source officielle : Mozilla demande de récupérer la liste depuis cette URL et nulle part ailleurs.
  final sourceUri = Uri.parse('https://publicsuffix.org/list/public_suffix_list.dat');
  final asset = File.fromUri(Platform.script.resolve('../$publicSuffixListAssetPath'));
  final versionPattern = RegExp(r'^// VERSION: (.+)$', multiLine: true);

  final current = asset.existsSync() ? asset.readAsStringSync() : '';
  final currentVersion = versionPattern.firstMatch(current)?.group(1)?.trim() ?? 'none';

  // 1. Téléchargement.
  stdout.writeln('🌐 Downloading $sourceUri');
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
  final String downloaded;
  try {
    final response = await (await client.getUrl(sourceUri)).close();
    if (response.statusCode != HttpStatus.ok) {
      stderr.writeln('❌ Download failed: HTTP ${response.statusCode}, asset kept as is');
      exit(1);
    }
    downloaded = await utf8.decoder.bind(response).join().timeout(const Duration(minutes: 1));
  } catch (error) {
    stderr.writeln('❌ Download failed: $error, asset kept as is');
    exit(1);
  } finally {
    client.close();
  }

  // 2. Validation : la vraie liste dépasse 300 000 caractères et contient toujours ces quatre marqueurs.
  final missingMarkers = [
    '===BEGIN ICANN DOMAINS===',
    '===END ICANN DOMAINS===',
    '===BEGIN PRIVATE DOMAINS===',
    '===END PRIVATE DOMAINS===',
  ].where((marker) => !downloaded.contains(marker)).toList();

  if (downloaded.length < 100000 || missingMarkers.isNotEmpty) {
    stderr.writeln(
      '❌ Invalid list (${downloaded.length} characters, missing markers: $missingMarkers), asset kept as is',
    );
    exit(1);
  }

  // 3. Écriture, seulement si la liste a changé. Passer par un fichier temporaire évite de laisser un asset à moitié
  // écrit si le script est interrompu.
  final downloadedVersion = versionPattern.firstMatch(downloaded)?.group(1)?.trim() ?? 'unknown';
  if (downloaded == current) {
    stdout.writeln('✅ Already up to date ($currentVersion)');
    return;
  }

  final temporary = File('${asset.path}.tmp');
  temporary.writeAsStringSync(downloaded, flush: true);
  temporary.renameSync(asset.path);

  stdout.writeln('✅ Updated: $currentVersion → $downloadedVersion');
}
