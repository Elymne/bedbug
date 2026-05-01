import 'package:cloud_firestore/cloud_firestore.dart';

/// Signature d'une fonction de parsing : reçoit une valeur dynamique et
/// retourne une valeur typée, ou `null` si la conversion échoue.
typedef Parser<T> = T? Function(dynamic value);

/// Classe utilitaire de parsing sécurisé pour les données issues de Firestore.
///
/// Toutes les méthodes retournent `null` plutôt que de lever une exception
/// lorsque la valeur ne correspond pas au type attendu. Cela permet de gérer
/// proprement les documents incomplets ou malformés sans interrompre
/// l'exécution.
class NoSqlParser {
  /// Retourne [value] en tant que [String], ou `null` si ce n'est pas une
  /// chaîne.
  static String? toStr(dynamic value) {
    return value is String ? value : null;
  }

  /// Retourne [value] en tant que [int], ou `null` si la conversion est
  /// impossible.
  ///
  /// Accepte également les [double] en les tronquant via [double.toInt].
  static int? toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return null;
  }

  /// Retourne [value] en tant que [double], ou `null` si la conversion est
  /// impossible.
  ///
  /// Accepte également les [int] en les promouvant via [int.toDouble].
  static double? toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return null;
  }

  /// Retourne [value] en tant que [bool], ou `null` si ce n'est pas un
  /// booléen.
  static bool? toBool(dynamic value) {
    return value is bool ? value : null;
  }

  /// Retourne [value] en tant que [num], ou `null` si ce n'est pas un nombre.
  static num? toNum(dynamic value) {
    return value is num ? value : null;
  }

  /// Retourne [value] en tant que [DateTime], ou `null` si la conversion est
  /// impossible.
  ///
  /// Accepte un [DateTime] directement ou un [Timestamp] Firestore converti
  /// via [Timestamp.toDate].
  static DateTime? toDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  /// Retourne [value] en tant que [Timestamp] Firestore, ou `null` si la
  /// conversion est impossible.
  ///
  /// Accepte un [Timestamp] directement ou un [DateTime] converti via
  /// [Timestamp.fromDate].
  static Timestamp? toTimestamp(dynamic value) {
    if (value is Timestamp) return value;
    if (value is DateTime) return Timestamp.fromDate(value);
    return null;
  }

  /// Retourne [value] en tant que [GeoPoint] Firestore, ou `null` si ce
  /// n'est pas un [GeoPoint].
  static GeoPoint? toGeoPoint(dynamic value) {
    return value is GeoPoint ? value : null;
  }

  /// Retourne [value] en tant que [DocumentReference] non typée, ou `null`
  /// si ce n'est pas une référence de document Firestore.
  static DocumentReference? toDocRef(dynamic value) {
    return value is DocumentReference ? value : null;
  }

  /// Retourne [value] en tant que [DocumentReference] typée sur [T], ou
  /// `null` si le type ne correspond pas.
  static DocumentReference<T>? toDocRefTyped<T>(dynamic value) {
    return value is DocumentReference<T> ? value : null;
  }

  /// Retourne [value] en tant que `List<T>`, ou `null` si [value] n'est pas
  /// une liste.
  ///
  /// Chaque élément est converti via [parser]. Les éléments dont la
  /// conversion retourne `null` sont silencieusement ignorés.
  static List<T>? toList<T>(dynamic value, Parser<T> parser) {
    if (value is! List) return null;
    final result = <T>[];
    for (final item in value) {
      final parsed = parser(item);
      if (parsed != null) {
        result.add(parsed);
      }
    }
    return result;
  }

  /// Retourne [value] en tant que `Map<String, dynamic>`, ou `null` si le
  /// type ne correspond pas exactement.
  static Map<String, dynamic>? toMap(dynamic value) {
    return value is Map<String, dynamic> ? value : null;
  }

  /// Retourne [value] en tant que `Map<String, T>`, ou `null` si [value]
  /// n'est pas une map.
  ///
  /// Les clés non-[String] et les valeurs dont la conversion retourne `null`
  /// sont silencieusement ignorées.
  static Map<String, T>? toMapOf<T>(dynamic value, Parser<T> parser) {
    if (value is! Map) return null;
    final result = <String, T>{};
    value.forEach((key, val) {
      if (key is String) {
        final parsed = parser(val);
        if (parsed != null) {
          result[key] = parsed;
        }
      }
    });
    return result;
  }

  /// Applique [parser] à [value] en encapsulant l'appel dans un `try/catch`.
  ///
  /// Retourne `null` si [parser] lève une exception. Utile pour les parsers
  /// susceptibles de planter sur certaines valeurs (ex. casting, `byName`).
  static T? safe<T>(dynamic value, Parser<T> parser) {
    try {
      return parser(value);
    } catch (_) {
      return null;
    }
  }

  /// Retourne [value] si non `null`, sinon retourne [fallback].
  static T or<T>(T? value, T fallback) {
    return value ?? fallback;
  }

  /// Retourne la valeur d'enum [T] dont le nom correspond à [value], ou
  /// `null` si aucune correspondance n'est trouvée ou si [value] est `null`.
  ///
  /// - [values] : la liste des valeurs de l'enum (`MyEnum.values`).
  static T? enumFromString<T>(String? value, List<T> values) {
    if (value == null) return null;
    for (final v in values) {
      final name = v.toString().split('.').last;
      if (name == value) return v;
    }
    return null;
  }
}
