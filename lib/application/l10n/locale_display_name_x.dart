import 'dart:ui';

/// Nom d'affichage des langues proposées par l'application.
///
/// Chaque langue est écrite dans sa propre langue (« Español », « العربية »)
/// et non traduite : quelqu'un qui ne comprend pas la langue actuelle de
/// l'app doit pouvoir y retrouver la sienne. Ces noms ne passent donc pas par
/// les fichiers de traduction.
extension LocaleDisplayNameX on Locale {
  /// Nom de la langue, écrit dans cette langue.
  String get displayName {
    return switch (languageCode) {
      'fr' => 'Français',
      'es' => 'Español',
      'it' => 'Italiano',
      'ar' => 'العربية',
      'zh' => '简体中文',
      _ => languageCode,
    };
  }
}
