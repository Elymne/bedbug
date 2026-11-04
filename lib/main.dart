import 'package:bedbug/application/app_root.widget.dart';
import 'package:bedbug/application/notifiers/passive_exchange.notifier.dart';
import 'package:bedbug/application/style/app_system_ui.config.dart';
import 'package:bedbug/core/config/app_config.dart';
import 'package:bedbug/resources/hive.initializer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // * Only for mobile.
  if (defaultTargetPlatform != TargetPlatform.android) {
    throw Exception('Cette application est uniquement compatible Android.');
  }

  // * Importe un fichier JSON de config en fonction de l'environnement.
  await AppConfig.init();

  // * Init de l'instance Hive (la base de données).
  await initHive();

  // * Je veux rendre la topbar de l'os opaque.
  SystemChrome.setSystemUIOverlayStyle(appSystemUiOverlayStyle);

  debugPrint('Starting Web App');

  // * L'échange ne dépend d'aucun écran : Android peut relancer l'app en arrière-plan, sans en afficher un seul.
  final container = ProviderContainer();
  container.read(passiveExchangeNotifierProvider);

  runApp(UncontrolledProviderScope(container: container, child: const AppRoot()));
}
