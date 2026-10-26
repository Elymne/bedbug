import 'package:bedbug/features/content/domain/entities/reaction.dart';
import 'package:bedbug/features/content/domain/repositories/reaction_repository.dart';
import 'package:bedbug/features/content/infrastructure/models/reaction_hive_model.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Provider du [HiveReactionRepository].
final reactionRepositoryProvider = Provider<ReactionRepository>((ref) {
  return HiveReactionRepository(ref.read(hiveReactionBoxProvider));
});

/// Provider de la [Box] Hive des réactions.
final hiveReactionBoxProvider = Provider<Box<ReactionHiveModel>>((ref) => Hive.box<ReactionHiveModel>('reactions'));

/// Implémentation de [ReactionRepository] utilisant Hive comme stockage local.
class HiveReactionRepository implements ReactionRepository {
  /// Crée un [HiveReactionRepository].
  HiveReactionRepository(this._box);

  final Box<ReactionHiveModel> _box;

  @override
  Future<void> addOne(Reaction entity) async {
    try {
      await _box.put(entity.id, ReactionHiveModel.fromEntity(entity));
    } on HiveError catch (error) {
      throw DatasourceException('HiveReactionRepository', error);
    }
  }

  @override
  Future<void> addMany(List<Reaction> entities) async {
    try {
      await _box.putAll({for (final entity in entities) entity.id: ReactionHiveModel.fromEntity(entity)});
    } on HiveError catch (error) {
      throw DatasourceException('HiveReactionRepository', error);
    }
  }

  @override
  Future<List<Reaction>> getAllByContentId(String contentId) async {
    try {
      return _box.values.where((model) => model.contentId == contentId).map((model) => model.toEntity()).toList();
    } on HiveError catch (error) {
      throw DatasourceException('HiveReactionRepository', error);
    }
  }

  @override
  Future<int> countByContentId(String contentId) async {
    try {
      return _box.values.where((model) => model.contentId == contentId).length;
    } on HiveError catch (error) {
      throw DatasourceException('HiveReactionRepository', error);
    }
  }

  @override
  Future<void> deleteMany(List<String> ids) async {
    try {
      await _box.deleteAll(ids);
    } on HiveError catch (error) {
      throw DatasourceException('HiveReactionRepository', error);
    }
  }

  @override
  Future<void> deleteAllByContentId(String contentId) async {
    try {
      final ids = _box.values.where((model) => model.contentId == contentId).map((model) => model.id).toList();
      await _box.deleteAll(ids);
    } on HiveError catch (error) {
      throw DatasourceException('HiveReactionRepository', error);
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _box.clear();
    } on HiveError catch (error) {
      throw DatasourceException('HiveReactionRepository', error);
    }
  }
}
