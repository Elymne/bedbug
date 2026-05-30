import 'package:bedbug/application/app_root.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/shared/config/app_config.dart';
import 'package:bedbug/shared/infrastructure/hive_initializer.dart';
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
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.background,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  debugPrint('Starting Web App');
  runApp(const ProviderScope(child: AppRoot()));
}
