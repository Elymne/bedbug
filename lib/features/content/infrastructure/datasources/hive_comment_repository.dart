import 'package:bedbug/features/content/domain/entities/comment.dart';
import 'package:bedbug/features/content/domain/repositories/comment_repository.dart';
import 'package:bedbug/features/content/infrastructure/models/comment_hive_model.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Provider de la [Box] Hive des commentaires.
final hiveCommentBoxProvider = Provider<Box<CommentHiveModel>>((ref) => Hive.box<CommentHiveModel>('comments'));

/// Provider du [HiveCommentRepository].
final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => HiveCommentRepository(ref.read(hiveCommentBoxProvider)),
);

/// Implémentation de [CommentRepository] utilisant Hive comme stockage local.
class HiveCommentRepository implements CommentRepository {
  /// Crée un [HiveCommentRepository].
  HiveCommentRepository(this._box);

  final Box<CommentHiveModel> _box;

  @override
  Future<Comment> addOne(Comment entity) async {
    try {
      await _box.put(entity.id, CommentHiveModel.fromEntity(entity));
      return entity;
    } on HiveError catch (error) {
      throw DatasourceException('HiveCommentRepository', error);
    }
  }

  @override
  Future<void> addMany(List<Comment> entities) async {
    try {
      await _box.putAll({for (final entity in entities) entity.id: CommentHiveModel.fromEntity(entity)});
    } on HiveError catch (error) {
      throw DatasourceException('HiveCommentRepository', error);
    }
  }

  @override
  Future<Comment> updateOne(Comment entity) async {
    try {
      if (!_box.containsKey(entity.id)) {
        throw DatasourceException('HiveCommentRepository', 'entity with id "${entity.id}" not found');
      }
      await _box.put(entity.id, CommentHiveModel.fromEntity(entity));
      return entity;
    } on DatasourceException {
      rethrow;
    } on HiveError catch (error) {
      throw DatasourceException('HiveCommentRepository', error);
    }
  }

  @override
  Future<void> updateMany(List<Comment> entities) async {
    try {
      for (final entity in entities) {
        if (!_box.containsKey(entity.id)) {
          throw DatasourceException('HiveCommentRepository', 'entity with id "${entity.id}" not found');
        }
      }
      await _box.putAll({for (final entity in entities) entity.id: CommentHiveModel.fromEntity(entity)});
    } on DatasourceException {
      rethrow;
    } on HiveError catch (error) {
      throw DatasourceException('HiveCommentRepository', error);
    }
  }

  @override
  Future<Comment?> getUnique(String id) async {
    try {
      return _box.get(id)?.toEntity();
    } on HiveError catch (error) {
      throw DatasourceException('HiveCommentRepository', error);
    }
  }

  @override
  Future<List<Comment>> getAll() async {
    try {
      return _box.values.map((model) => model.toEntity()).toList();
    } on HiveError catch (error) {
      throw DatasourceException('HiveCommentRepository', error);
    }
  }

  @override
  Stream<List<Comment>> watchAll() async* {
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
      throw DatasourceException('HiveCommentRepository', error);
    }
  }

  @override
  Future<void> deleteMany(List<String> ids) async {
    try {
      await _box.deleteAll(ids);
    } on HiveError catch (error) {
      throw DatasourceException('HiveCommentRepository', error);
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _box.clear();
    } on HiveError catch (error) {
      throw DatasourceException('HiveCommentRepository', error);
    }
  }

  @override
  Future<List<Comment>> findMany(CommentRepositoryParams params) async {
    try {
      return _applyParams(params);
    } on HiveError catch (error) {
      throw DatasourceException('HiveCommentRepository', error);
    }
  }

  @override
  Stream<List<Comment>> watchMany(CommentRepositoryParams params) async* {
    yield _applyParams(params);
    await for (final _ in _box.watch()) {
      yield _applyParams(params);
    }
  }

  /// Applique les filtres, le tri et la limite des [params] sur les valeurs de la box.
  List<Comment> _applyParams(CommentRepositoryParams params) {
    var results = _box.values.map((model) => model.toEntity()).toList();

    if (params.authorId != null) {
      results = results.where((comment) => comment.authorId == params.authorId).toList();
    }

    if (params.orderBy != null) {
      results.sort((a, b) {
        final comparison = switch (params.orderBy!.field) {
          'createdAt' => a.createdAt.compareTo(b.createdAt),
          'updatedAt' => a.updatedAt.compareTo(b.updatedAt),
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
