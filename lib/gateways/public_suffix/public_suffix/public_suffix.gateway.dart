/// Accès à la liste des suffixes publics (Public Suffix List de Mozilla).
///
/// Un suffixe public est un domaine sous lequel n'importe qui peut obtenir
/// son propre site : `com`, `co.uk`, mais aussi `github.io` ou
/// `blogspot.com`. Autoriser un suffixe public, c'est autoriser des
/// millions de sites inconnus : les listes de domaines doivent donc les
/// refuser, ce qui ne se devine pas sans la liste.
abstract class PublicSuffixGateway {
  /// Indique si [host] est lui-même un suffixe public.
  ///
  /// En cas de doute (liste illisible, domaine inattendu), répond `true` :
  /// mieux vaut refuser une règle légitime qu'en accepter une trop large.
  ///
  /// - [host] : nom de domaine valide, en minuscules.
  Future<bool> isPublicSuffix(String host);
}
