import 'package:bedbug/application/app_root.dart';
import 'package:bedbug/shared/config/app_config.dart';
import 'package:bedbug/shared/infrastructure/hive_initializer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // * Only for mobile.
  if (kIsWeb) {
    // throw Exception(
    //   "This is a web project, can't be launched from a ios or android device",
    // );
  }

  // * Importe un fichier JSON de config en fonction de l'environnement.
  await AppConfig.init();
  await initHive();

  debugPrint('Starting Web App');
  runApp(const ProviderScope(child: AppRoot()));
}
