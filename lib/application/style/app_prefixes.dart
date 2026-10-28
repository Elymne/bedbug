/// Préfixes d'affichage des noms de l'app, à la manière de Reddit (`r/`, `u/`).
///
/// Toujours affichés devant le nom via `AppPrefixedText`, en gras avec un léger effet ghost.
class AppPrefixes {
  AppPrefixes._();

  /// Préfixe d'un flair : `f/france`.
  static const String flair = 'f/';

  /// Préfixe d'une signature : `s/pseudo`.
  static const String signature = 's/';
}
