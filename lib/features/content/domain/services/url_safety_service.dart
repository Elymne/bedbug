import 'package:bedbug/features/content/domain/object_values/safe_url.dart';
import 'package:bedbug/shared/domain/service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Longueur maximale, en caractères, d'une URL acceptée.
///
/// Largement assez pour l'URL d'un média ou d'une page ; au-delà, c'est
/// presque toujours une URL fabriquée pour piéger un analyseur.
const int maxSafeUrlLength = 2048;

/// Longueur maximale, en caractères, d'un nom de domaine (RFC 1035).
const int maxHostNameLength = 253;

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

/// Un label de nom de domaine : lettres minuscules, chiffres et tirets, sans tiret au début ni à la fin, 63 caractères max.
final RegExp _labelPattern = RegExp(r'^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$');

/// Le dernier label (extension) : commence forcément par une lettre.
///
/// C'est ce qui écarte toutes les écritures d'adresses IP : `127.0.0.1`,
/// `0x7f.0.0.1` ou `0177.0.0.1` finissent toutes par un label qui commence
/// par un chiffre.
final RegExp _topLevelPattern = RegExp(r'^[a-z]');

/// Provider du [UrlSafetyService].
final urlSafetyServiceProvider = Provider<UrlSafetyService>((ref) => const UrlSafetyService());

/// Vérifie les URLs et les noms de domaine reçus des pairs, avant toute comparaison avec une liste.
///
/// Les contenus voyagent de pair à pair : n'importe qui peut y glisser une
/// URL fabriquée pour paraître pointer vers un site autorisé tout en
/// chargeant un autre site (`https://i.imgur.com@evil.com`). Avant de
/// comparer un domaine à une liste, il faut donc être certain que c'est bien
/// ce domaine que le client HTTP contactera. Ce service n'accepte que des
/// URLs dont la partie domaine ne peut se lire que d'une seule façon, et
/// refuse tout le reste plutôt que d'essayer de le corriger.
class UrlSafetyService extends Service {
  /// Crée un [UrlSafetyService].
  const UrlSafetyService();

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
  ///   un nom mal formé (voir [isValidHostName]) ;
  /// - l'analyseur d'URL de Dart ne lit pas le même domaine : une
  ///   divergence entre deux analyseurs est précisément ce qu'exploitent
  ///   les URLs piégées.
  ///
  /// - [raw] : URL telle que reçue, non nettoyée.
  SafeUrl? parse(String raw) {
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
    if (!isValidHostName(host)) {
      return null;
    }

    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme != 'https' || uri.host != host || uri.userInfo.isNotEmpty || uri.hasPort) {
      return null;
    }

    return SafeUrl(url: '$_httpsPrefix$host${rest.substring(authority.length)}', host: host);
  }

  /// Indique si [host] est un nom de domaine valide, déjà en minuscules.
  ///
  /// Un nom de domaine n'est accepté que sous sa forme ASCII canonique, en
  /// minuscules, pour qu'il n'existe qu'une seule façon de l'écrire. Toute
  /// variante (caractère Unicode qui ressemble à une lettre latine, point
  /// pleine chasse, adresse IP, point final, label vide) est refusée plutôt
  /// que normalisée : normaliser, c'est risquer de ne pas normaliser comme
  /// le client HTTP qui chargera l'URL.
  ///
  /// Exige au moins deux labels (pas de `localhost`), chacun conforme à la
  /// syntaxe des noms de domaine, et un dernier label qui commence par une
  /// lettre (pas d'adresse IP). Les noms internationalisés ne sont acceptés
  /// que sous leur forme punycode (`xn--…`).
  ///
  /// - [host] : nom de domaine à vérifier.
  bool isValidHostName(String host) {
    if (host.isEmpty || host.length > maxHostNameLength) {
      return false;
    }
    final labels = host.split('.');
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
