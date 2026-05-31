import 'package:flutter/foundation.dart';

import 'app_config_model.dart';
import 'config_loader.dart';

/// Singleton statique donnant accès à la configuration de l'application.
///
/// Doit être initialisé via [init] au démarrage de l'application,
/// avant tout accès à [instance].
class AppConfig {
  static late final AppConfigModel _config;

  /// Charge et initialise la configuration depuis les assets via [ConfigLoader].
  ///
  /// À appeler une seule fois dans main avant de charger l'app.
  static Future<void> init() async {
    _config = await ConfigLoader.load();
    debugPrint('Configuration loaded from json file.');
  }

  /// Retourne la configuration chargée.
  ///
  /// Lève une erreur si [init] n'a pas été appelé au préalable.
  static AppConfigModel get instance => _config;
}
