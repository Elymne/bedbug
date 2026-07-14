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
  Future<Content> updateOne(Content entity) async {
    try {
      if (!_box.containsKey(entity.id)) {
        throw DatasourceException('HiveContentRepository', 'entity with id "${entity.id}" not found');
      }
      await _box.put(entity.id, ContentHiveModel.fromEntity(entity));
      return entity;
    } on DatasourceException {
      rethrow;
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
  Future<Content?> getUnique(String id) async {
    try {
      return _box.get(id)?.toEntity();
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
  Stream<List<Content>> watchAll() async* {
    yield _box.values.map((model) => model.toEntity()).toList();
    await for (final _ in _box.watch()) {
      yield _box.values.map((model) => model.toEntity()).toList();
    }
  }

  @override
  Future<void> deleteOne(String id) async {
    try {
      await _box.delete(id);
    } on HiveError catch (error) {
      throw DatasourceException('HiveContentRepository', error);
    }
  }

  @override
  Future<void> deleteMany(List<String> ids) async {
    try {
      await _box.deleteAll(ids);
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
  Future<List<Content>> findMany(ContentRepositoryParams params) async {
    try {
      return _applyParams(params);
    } on HiveError catch (error) {
      throw DatasourceException('HiveContentRepository', error);
    }
  }

  @override
  Stream<List<Content>> watchMany(ContentRepositoryParams params) async* {
    yield _applyParams(params);
    await for (final _ in _box.watch()) {
      yield _applyParams(params);
    }
  }

  /// Applique les filtres, le tri et la limite des [params] sur les valeurs de la box.
  List<Content> _applyParams(ContentRepositoryParams params) {
    var results = _box.values.map((model) => model.toEntity()).toList();

    if (params.authorId != null) {
      results = results.where((content) => content.authorId == params.authorId).toList();
    }

    if (params.orderBy != null) {
      results.sort((a, b) {
        final comparison = switch (params.orderBy!.field) {
          'createdAt' => a.createdAt.compareTo(b.createdAt),
          'updatedAt' => a.updatedAt.compareTo(b.updatedAt),
          'displayScore' => a.displayScore.compareTo(b.displayScore),
          _ => 0,
        };
        return params.orderBy!.descending ? -comparison : comparison;
      });
    }

    if (params.limit != null) {
      return results.take(params.limit!).toList();
    }

    return results;
  }
}
