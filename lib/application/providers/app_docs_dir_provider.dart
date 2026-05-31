import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Fournit le dossier de documents de l'application.
///
/// Résolu une seule fois et mis en cache pour toute la durée de vie de l'app.
final appDocsDirProvider = FutureProvider<Directory>((ref) async {
  return getApplicationDocumentsDirectory();
});
