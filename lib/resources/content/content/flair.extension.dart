/// Normalisation du flair saisi à la main par l'auteur d'un contenu.
///
/// Le flair est un texte libre : l'utilisateur peut écrire `f/france`,
/// `/france`, `france ` ou `//France`. Sans normalisation, ces variantes
/// seraient stockées et diffusées comme des flairs distincts. Cette extension
/// garantit une forme canonique unique, stockée sans préfixe (`f/` est ajouté
/// à l'affichage).
extension FlairExtension on String {
  /// Retourne le flair normalisé, ou `null` s'il ne reste rien après nettoyage.
  ///
  /// Supprime les espaces en bordure et le préfixe initial (`f/` ou `/`,
  /// éventuellement répétés), puis passe en minuscules pour que `f/France` et
  /// `france` désignent le même flair.
  String? toFlair() {
    final normalized = trim().replaceFirst(RegExp('^(f/|/)+', caseSensitive: false), '').trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
