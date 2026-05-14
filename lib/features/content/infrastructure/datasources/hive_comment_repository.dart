import 'package:bedbug/features/content/domain/entities/comment.dart';
import 'package:bedbug/features/content/domain/repositories/comment_repository.dart';
import 'package:bedbug/features/content/infrastructure/models/comment_hive_model.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/query/page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Provider de la [Box] Hive des commentaires.
final hiveCommentBoxProvider = Provider<Box<CommentHiveModel>>(
  (ref) => Hive.box<CommentHiveModel>('comments'),
);

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
  Future<Comment> updateOne(Comment entity) async {
    try {
      await _box.put(entity.id, CommentHiveModel.fromEntity(entity));
      return entity;
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
  Future<void> deleteOne(String id) async {
    try {
      await _box.delete(id);
    } on HiveError catch (error) {
      throw DatasourceException('HiveCommentRepository', error);
    }
  }

  @override
  Future<Page<Comment>> getMany(CommentRepositoryParams params) async {
    try {
      var results = _box.values.map((model) => model.toEntity()).toList();

      if (params.authorId != null) {
        results = results
            .where((comment) => comment.authorId == params.authorId)
            .toList();
      }

      return Page(items: results, total: results.length);
    } on HiveError catch (error) {
      throw DatasourceException('HiveCommentRepository', error);
    }
  }
}
