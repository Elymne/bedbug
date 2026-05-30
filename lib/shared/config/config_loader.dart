import 'dart:convert';

import 'package:bedbug/shared/config/app_config_model.dart';
import 'package:flutter/services.dart';

/// Charge la configuration de l'application depuis les assets selon l'environnement.
class ConfigLoader {
  /// Lit le fichier JSON de configuration correspondant à la variable d'environnement `ENV`
  /// et retourne un [AppConfigModel] désérialisé.
  ///
  /// Valeurs de `ENV` supportées :
  /// - `production` → `assets/config/production.json`
  /// - `preproduction` → `assets/config/preproduction.json`
  /// - toute autre valeur (défaut : `development`) → `assets/config/development.json`
  ///
  /// Lève une [Exception] si le fichier est introuvable ou mal formé.
  static Future<AppConfigModel> load() async {
    try {
      const env = String.fromEnvironment('ENV', defaultValue: 'development');

      final raw = switch (env) {
        'production' => await rootBundle.loadString('assets/config/production.json'),
        'preproduction' => await rootBundle.loadString('assets/config/preproduction.json'),
        _ => await rootBundle.loadString('assets/config/development.json'),
      };

      final jsonMap = jsonDecode(raw) as Map<String, dynamic>;

      return AppConfigModel.fromJson(jsonMap);
    } catch (e) {
      throw Exception('Failed to load app config: $e');
    }
  }
}
