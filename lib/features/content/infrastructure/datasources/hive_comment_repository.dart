import 'package:bedbug/features/content/domain/entities/comment.dart';
import 'package:bedbug/features/content/domain/repositories/comment_repository.dart';
import 'package:bedbug/features/content/infrastructure/models/comment_hive_model.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Provider de la [Box] Hive des commentaires.
final hiveCommentBoxProvider = Provider<Box<CommentHiveModel>>((ref) => Hive.box<CommentHiveModel>('comments'));

/// Provider du [HiveCommentRepository].
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return HiveCommentRepository(ref.read(hiveCommentBoxProvider));
});

/// Implémentation de [CommentRepository] utilisant Hive comme stockage local.
class HiveCommentRepository implements CommentRepository {
  /// Crée un [HiveCommentRepository].
  HiveCommentRepository(this._box);

  final Box<CommentHiveModel> _box;

  @override
  Future<void> addOne(Comment entity) async {
    try {
      await _box.put(entity.id, CommentHiveModel.fromEntity(entity));
    } on HiveError catch (error) {
      throw DatasourceException('HiveCommentRepository', error);
    }
  }

  @override
  Future<List<Comment>> getAllByContentId(String contentId) async {
    try {
      return _box.values.where((model) => model.contentId == contentId).map((model) => model.toEntity()).toList();
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
  Future<void> deleteAllByContentId(String contentId) async {
    try {
      final ids = _box.values.where((model) => model.contentId == contentId).map((model) => model.id).toList();
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
}
