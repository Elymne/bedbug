import 'package:bedbug/resources/content/seen_content/seen_content.config.dart';
import 'package:bedbug/resources/content/seen_content/seen_content.entity.dart';
import 'package:bedbug/resources/content/seen_content/seen_content.model.hive.dart';
import 'package:bedbug/resources/content/seen_content/seen_content.repository.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Provider de la [Box] Hive des contenus déjà reçus ou supprimés, indexée par identifiant du contenu.
final hiveSeenContentBoxProvider = Provider<Box<SeenContentHiveModel>>((ref) {
  return Hive.box<SeenContentHiveModel>(seenContentBoxName);
});

/// Provider du [HiveSeenContentRepository].
final seenContentRepositoryProvider = Provider<SeenContentRepository>((ref) {
  return HiveSeenContentRepository(ref.read(hiveSeenContentBoxProvider));
});

/// Implémentation de [SeenContentRepository] utilisant Hive.
class HiveSeenContentRepository implements SeenContentRepository {
  /// Crée un [HiveSeenContentRepository].
  ///
  /// - [_box] : box Hive des contenus déjà reçus ou supprimés.
  HiveSeenContentRepository(this._box);

  final Box<SeenContentHiveModel> _box;

  @override
  Future<void> addMany(Iterable<SeenContent> entities) async {
    try {
      await _box.putAll({for (final entity in entities) entity.id: SeenContentHiveModel.fromEntity(entity)});
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
      final expiredKeys = _box.values.where((model) => model.createdAt.isBefore(date)).map((model) => model.id);
      await _box.deleteAll(expiredKeys.toList());
    } on HiveError catch (error) {
      throw DatasourceException('HiveSeenContentRepository', error);
    }
  }
}
