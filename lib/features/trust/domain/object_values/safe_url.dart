import 'package:bedbug/features/trust/domain/extensions/host_name_extension.dart';
import 'package:bedbug/shared/domain/value_object.dart';

/// Longueur maximale, en caractères, d'une URL acceptée.
///
/// Largement assez pour l'URL d'un média ou d'une page ; au-delà, c'est
/// presque toujours une URL fabriquée pour piéger un analyseur.
const int maxSafeUrlLength = 2048;

/// Caractères autorisés dans une URL : ceux de la RFC 3986, en ASCII imprimable uniquement.
///
/// Exclut les espaces et caractères de contrôle, tout caractère Unicode
/// (lettres qui imitent des lettres latines, points pleine chasse,
/// caractères invisibles, inversion du sens d'écriture), et les caractères
/// que les analyseurs d'URL interprètent différemment, comme `\`, que les
/// navigateurs lisent comme un `/`.
final RegExp _allowedCharacters = RegExp(r"^[A-Za-z0-9\-._~:/?#\[\]@!$&'()*+,;=%]+$");

/// Un `%` qui n'est pas suivi de deux chiffres hexadécimaux.
final RegExp _invalidPercentEncoding = RegExp('%(?![0-9A-Fa-f]{2})');

/// Fin de la partie « domaine » d'une URL : début du chemin, de la requête ou du fragment.
final RegExp _authorityEnd = RegExp('[/?#]');

/// Seul schéma accepté.
const String _httpsPrefix = 'https://';

/// URL web vérifiée : en https, vers un nom de domaine sans ambiguïté possible.
///
/// Les contenus voyagent de pair à pair : n'importe qui peut y glisser une
/// URL fabriquée pour paraître pointer vers un site autorisé tout en
/// chargeant un autre site (`https://i.imgur.com@evil.com`). Avant de
/// comparer un domaine à une liste, il faut donc être certain que c'est bien
/// ce domaine que le client HTTP contactera. [tryParse] n'accepte que des
/// URLs dont la partie domaine ne peut se lire que d'une seule façon, et
/// refuse tout le reste plutôt que d'essayer de le corriger.
class SafeUrl extends ValueObject {
  const SafeUrl._(this.url, this.host);

  /// URL complète, schéma et domaine en minuscules, le reste tel que reçu.
  ///
  /// C'est cette URL, et elle seule, qui doit être chargée : c'est elle qui
  /// a été vérifiée.
  final String url;

  /// Nom de domaine contacté, en minuscules (ex. `i.imgur.com`).
  final String host;

  /// Retourne l'URL vérifiée correspondant à [raw], ou `null` si elle est refusée.
  ///
  /// Une URL est refusée si :
  /// - elle est vide ou dépasse [maxSafeUrlLength] caractères ;
  /// - elle contient un caractère hors de l'ASCII imprimable de la RFC 3986
  ///   (espace, caractère de contrôle, Unicode, `\`, `<`, `"`…), ou un `%`
  ///   mal formé ;
  /// - elle ne commence pas par `https://` ;
  /// - sa partie domaine contient autre chose qu'un nom de domaine : un
  ///   identifiant (`user@`), un port (`:8080`), une adresse IP, un `%`, ou
  ///   un nom mal formé (voir [HostNameExtension.isValidHostName]) ;
  /// - l'analyseur d'URL de Dart ne lit pas le même domaine : une
  ///   divergence entre deux analyseurs est précisément ce qu'exploitent
  ///   les URLs piégées.
  ///
  /// - [raw] : URL telle que reçue, non nettoyée.
  static SafeUrl? tryParse(String raw) {
    if (raw.isEmpty || raw.length > maxSafeUrlLength) {
      return null;
    }
    if (!_allowedCharacters.hasMatch(raw) || _invalidPercentEncoding.hasMatch(raw)) {
      return null;
    }
    if (raw.length <= _httpsPrefix.length || raw.substring(0, _httpsPrefix.length).toLowerCase() != _httpsPrefix) {
      return null;
    }

    final rest = raw.substring(_httpsPrefix.length);
    final authorityEndIndex = rest.indexOf(_authorityEnd);
    final authority = authorityEndIndex == -1 ? rest : rest.substring(0, authorityEndIndex);
    final host = authority.toLowerCase();
    if (!host.isValidHostName) {
      return null;
    }

    final Uri uri;
    try {
      uri = Uri.parse(raw);
    } on FormatException {
      return null;
    }
    if (uri.scheme != 'https' || uri.host != host || uri.userInfo.isNotEmpty || uri.hasPort) {
      return null;
    }

    return SafeUrl._('$_httpsPrefix$host${rest.substring(authority.length)}', host);
  }

  @override
  bool operator ==(Object other) {
    return other is SafeUrl && other.url == url;
  }

  @override
  int get hashCode {
    return url.hashCode;
  }

  @override
  String toString() {
    return url;
  }
}
