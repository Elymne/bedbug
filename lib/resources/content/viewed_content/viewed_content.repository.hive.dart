import 'package:bedbug/resources/content/viewed_content/viewed_content.config.dart';
import 'package:bedbug/resources/content/viewed_content/viewed_content.entity.dart';
import 'package:bedbug/resources/content/viewed_content/viewed_content.model.hive.dart';
import 'package:bedbug/resources/content/viewed_content/viewed_content.repository.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Provider de la [Box] Hive des contenus vus, indexée par identifiant du contenu.
final hiveViewedContentBoxProvider = Provider<Box<ViewedContentHiveModel>>((ref) {
  return Hive.box<ViewedContentHiveModel>(viewedContentBoxName);
});

/// Provider du [HiveViewedContentRepository].
final viewedContentRepositoryProvider = Provider<ViewedContentRepository>((ref) {
  return HiveViewedContentRepository(ref.read(hiveViewedContentBoxProvider));
});

/// Implémentation de [ViewedContentRepository] utilisant Hive.
class HiveViewedContentRepository implements ViewedContentRepository {
  /// Crée un [HiveViewedContentRepository].
  ///
  /// - [_box] : box Hive des contenus vus.
  HiveViewedContentRepository(this._box);

  final Box<ViewedContentHiveModel> _box;

  @override
  Future<Set<String>> getAllIds() async {
    try {
      return _box.keys.cast<String>().toSet();
    } on HiveError catch (error) {
      throw DatasourceException('HiveViewedContentRepository', error);
    }
  }

  @override
  Future<void> addOne(ViewedContent entity) async {
    try {
      await _box.put(entity.id, ViewedContentHiveModel.fromEntity(entity));
    } on HiveError catch (error) {
      throw DatasourceException('HiveViewedContentRepository', error);
    }
  }

  @override
  Future<void> deleteMany(Iterable<String> ids) async {
    try {
      await _box.deleteAll(ids);
    } on HiveError catch (error) {
      throw DatasourceException('HiveViewedContentRepository', error);
    }
  }
}
