/// Préfixes d'affichage des noms de l'app, à la manière de Reddit (`r/`, `u/`).
///
/// Toujours affichés en couleur primaire devant le nom, via `AppPrefixedText`.
class AppPrefixes {
  AppPrefixes._();

  /// Préfixe d'un flair : `f/france`.
  static const String flair = 'f/';

  /// Préfixe d'une signature : `s/pseudo`.
  static const String signature = 's/';
}
