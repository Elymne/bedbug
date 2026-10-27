/// Longueur maximale, en caractères, d'un nom de domaine (RFC 1035).
const int maxHostNameLength = 253;

/// Un label de nom de domaine : lettres minuscules, chiffres et tirets, sans tiret au début ni à la fin, 63 caractères max.
final RegExp _labelPattern = RegExp(r'^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$');

/// Le dernier label (extension) : commence forcément par une lettre.
///
/// C'est ce qui écarte toutes les écritures d'adresses IP : `127.0.0.1`,
/// `0x7f.0.0.1` ou `0177.0.0.1` finissent toutes par un label qui commence
/// par un chiffre.
final RegExp _topLevelPattern = RegExp(r'^[a-z]');

/// Validation stricte d'un nom de domaine.
///
/// Les URLs reçues des pairs ne sont pas dignes de confiance : un nom de
/// domaine n'est accepté que sous sa forme ASCII canonique, en minuscules,
/// pour qu'il n'existe qu'une seule façon de l'écrire. Toute variante
/// (caractère Unicode qui ressemble à une lettre latine, point pleine
/// chasse, adresse IP, point final, label vide) est refusée plutôt que
/// normalisée : normaliser, c'est risquer de ne pas normaliser comme le
/// client HTTP qui chargera l'URL.
extension HostNameExtension on String {
  /// Indique si cette chaîne est un nom de domaine valide, déjà en minuscules.
  ///
  /// Exige au moins deux labels (pas de `localhost`), chacun conforme à la
  /// syntaxe des noms de domaine, et un dernier label qui commence par une
  /// lettre (pas d'adresse IP). Les noms internationalisés ne sont acceptés
  /// que sous leur forme punycode (`xn--…`).
  bool get isValidHostName {
    if (isEmpty || length > maxHostNameLength) {
      return false;
    }
    final labels = split('.');
    if (labels.length < 2) {
      return false;
    }
    for (final label in labels) {
      if (!_labelPattern.hasMatch(label)) {
        return false;
      }
    }
    return _topLevelPattern.hasMatch(labels.last);
  }
}
