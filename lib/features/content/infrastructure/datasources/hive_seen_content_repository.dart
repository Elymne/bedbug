import 'package:bedbug/features/content/domain/repositories/seen_content_repository.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Nom de la box Hive des identifiants de contenus déjà vus.
const String seenContentBoxName = 'seen_contents';

/// Provider de la [Box] Hive des identifiants déjà vus : identifiant du contenu → date de vue en millisecondes.
final hiveSeenContentBoxProvider = Provider<Box<int>>((ref) => Hive.box<int>(seenContentBoxName));

/// Provider du [HiveSeenContentRepository].
final seenContentRepositoryProvider = Provider<SeenContentRepository>((ref) {
  return HiveSeenContentRepository(ref.read(hiveSeenContentBoxProvider));
});

/// Implémentation de [SeenContentRepository] utilisant Hive.
///
/// Une simple box d'entiers suffit : la clé est l'identifiant du contenu, la valeur la date de vue en
/// millisecondes. Pas de modèle ni de `typeId` à déclarer.
class HiveSeenContentRepository implements SeenContentRepository {
  /// Crée un [HiveSeenContentRepository].
  HiveSeenContentRepository(this._box);

  final Box<int> _box;

  @override
  Future<void> addMany(Iterable<String> ids, DateTime seenAt) async {
    try {
      final millis = seenAt.millisecondsSinceEpoch;
      await _box.putAll({for (final id in ids) id: millis});
    } on HiveError catch (error) {
      throw DatasourceException('HiveSeenContentRepository', error);
    }
  }

  @override
  Future<Set<String>> getSeenAmong(Set<String> ids) async {
    try {
      return ids.where(_box.containsKey).toSet();
    } on HiveError catch (error) {
      throw DatasourceException('HiveSeenContentRepository', error);
    }
  }

  @override
  Future<void> deleteSeenBefore(DateTime date) async {
    try {
      final limit = date.millisecondsSinceEpoch;
      final expiredKeys = _box.keys.where((key) => (_box.get(key) ?? 0) < limit).toList();
      await _box.deleteAll(expiredKeys);
    } on HiveError catch (error) {
      throw DatasourceException('HiveSeenContentRepository', error);
    }
  }
}
