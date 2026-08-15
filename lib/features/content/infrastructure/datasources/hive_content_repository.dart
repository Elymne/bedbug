import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/repositories/content_repository.dart';
import 'package:bedbug/features/content/infrastructure/models/content_hive_model.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Provider du [HiveContentRepository].
final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => HiveContentRepository(ref.read(hiveContentBoxProvider)),
);

/// Provider de la [Box] Hive des contenus.
final hiveContentBoxProvider = Provider<Box<ContentHiveModel>>((ref) => Hive.box<ContentHiveModel>('contents'));

/// Implémentation de [ContentRepository] utilisant Hive comme stockage local.
class HiveContentRepository implements ContentRepository {
  /// Crée un [HiveContentRepository].
  HiveContentRepository(this._box);

  final Box<ContentHiveModel> _box;

  @override
  Future<Content> addOne(Content entity) async {
    try {
      await _box.put(entity.id, ContentHiveModel.fromEntity(entity));
      return entity;
    } on HiveError catch (error) {
      throw DatasourceException('HiveContentRepository', error);
    }
  }

  @override
  Future<void> addMany(List<Content> entities) async {
    try {
      await _box.putAll({for (final entity in entities) entity.id: ContentHiveModel.fromEntity(entity)});
    } on HiveError catch (error) {
      throw DatasourceException('HiveContentRepository', error);
    }
  }

  @override
  Future<void> updateMany(List<Content> entities) async {
    try {
      for (final entity in entities) {
        if (!_box.containsKey(entity.id)) {
          throw DatasourceException('HiveContentRepository', 'entity with id "${entity.id}" not found');
        }
      }
      await _box.putAll({for (final entity in entities) entity.id: ContentHiveModel.fromEntity(entity)});
    } on DatasourceException {
      rethrow;
    } on HiveError catch (error) {
      throw DatasourceException('HiveContentRepository', error);
    }
  }

  @override
  Future<List<Content>> getAll() async {
    try {
      return _box.values.map((model) => model.toEntity()).toList();
    } on HiveError catch (error) {
      throw DatasourceException('HiveContentRepository', error);
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _box.clear();
    } on HiveError catch (error) {
      throw DatasourceException('HiveContentRepository', error);
    }
  }

  @override
  Future<List<Content>> getAllOrderedByDisplayScoreDesc() async {
    try {
      final results = _box.values.map((model) => model.toEntity()).toList();
      results.sort((a, b) => b.displayScore.compareTo(a.displayScore));
      return results;
    } on HiveError catch (error) {
      throw DatasourceException('HiveContentRepository', error);
    }
  }
}
