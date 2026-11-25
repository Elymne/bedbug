import 'dart:convert';

import 'package:drift/drift.dart';

/// Stocke une date en millisecondes depuis l'epoch.
///
/// Drift stocke par défaut les `DateTime` en secondes : on perdrait les millisecondes, alors que l'échange compare des
/// dates de réaction à la milliseconde près. Un entier permet aussi de comparer et trier les dates directement en SQL.
class MillisDateTimeConverter extends TypeConverter<DateTime, int> {
  /// Crée le convertisseur, sans état.
  const MillisDateTimeConverter();

  /// Relit la date stockée, en heure locale.
  ///
  /// [fromDb] : nombre de millisecondes depuis l'epoch.
  @override
  DateTime fromSql(int fromDb) {
    return DateTime.fromMillisecondsSinceEpoch(fromDb);
  }

  /// Convertit la date en millisecondes depuis l'epoch.
  ///
  /// [value] : date à stocker.
  @override
  int toSql(DateTime value) {
    return value.millisecondsSinceEpoch;
  }
}

/// Stocke une liste de chaînes en JSON dans une colonne texte.
///
/// Sert aux listes lues toujours en entier avec leur ligne et sur lesquelles aucune requête ne filtre (frames d'avatar,
/// motifs de confiance, URL de médias) : une table enfant coûterait une jointure à chaque lecture sans rien apporter.
class StringListConverter extends TypeConverter<List<String>, String> {
  /// Crée le convertisseur, sans état.
  const StringListConverter();

  /// Relit la liste depuis son JSON.
  ///
  /// [fromDb] : tableau JSON de chaînes.
  @override
  List<String> fromSql(String fromDb) {
    return (jsonDecode(fromDb) as List<dynamic>).cast<String>();
  }

  /// Encode la liste en tableau JSON.
  ///
  /// [value] : liste à stocker.
  @override
  String toSql(List<String> value) {
    return jsonEncode(value);
  }
}

/// Stocke une liste d'entiers en JSON dans une colonne texte.
///
/// Même usage que [StringListConverter], pour des valeurs d'enum stockées par leur code (tags, genres de médias).
class IntListConverter extends TypeConverter<List<int>, String> {
  /// Crée le convertisseur, sans état.
  const IntListConverter();

  /// Relit la liste depuis son JSON.
  ///
  /// [fromDb] : tableau JSON d'entiers.
  @override
  List<int> fromSql(String fromDb) {
    return (jsonDecode(fromDb) as List<dynamic>).cast<int>();
  }

  /// Encode la liste en tableau JSON.
  ///
  /// [value] : liste à stocker.
  @override
  String toSql(List<int> value) {
    return jsonEncode(value);
  }
}

/// Stocke une table d'association entier → chaîne en JSON dans une colonne texte.
///
/// Sert aux liens sociaux d'une signature, indexés par le code de leur réseau. JSON n'accepte que des clés textuelles :
/// les codes sont donc écrits en texte puis relus en entiers.
class IntStringMapConverter extends TypeConverter<Map<int, String>, String> {
  /// Crée le convertisseur, sans état.
  const IntStringMapConverter();

  /// Relit l'association depuis son JSON.
  ///
  /// [fromDb] : objet JSON dont les clés sont des entiers écrits en texte.
  @override
  Map<int, String> fromSql(String fromDb) {
    final decoded = jsonDecode(fromDb) as Map<String, dynamic>;
    return {for (final entry in decoded.entries) int.parse(entry.key): entry.value as String};
  }

  /// Encode l'association en objet JSON.
  ///
  /// [value] : association à stocker.
  @override
  String toSql(Map<int, String> value) {
    return jsonEncode({for (final entry in value.entries) '${entry.key}': entry.value});
  }
}
