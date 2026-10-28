import 'package:bedbug/shared/domain/value_object.dart';

/// URL web vérifiée : en https, vers un nom de domaine sans ambiguïté possible.
///
/// Ne se crée qu'avec `UrlSafetyService.parse`, qui garantit que la partie
/// domaine ne peut se lire que d'une seule façon : c'est ce qui permet de
/// la comparer sans risque aux listes de domaines.
class SafeUrl extends ValueObject {
  /// Crée une [SafeUrl].
  ///
  /// - [url] : URL complète, déjà vérifiée.
  /// - [host] : nom de domaine de [url], en minuscules.
  const SafeUrl({required this.url, required this.host});

  /// URL complète, schéma et domaine en minuscules, le reste tel que reçu.
  ///
  /// C'est cette URL, et elle seule, qui doit être chargée : c'est elle qui
  /// a été vérifiée.
  final String url;

  /// Nom de domaine contacté, en minuscules (ex. `i.imgur.com`).
  final String host;

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
