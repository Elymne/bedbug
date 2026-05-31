import 'package:bedbug/features/content/domain/entities/sub.dart';
import 'package:bedbug/features/content/domain/repositories/sub_repository.dart';
import 'package:bedbug/features/content/infrastructure/models/sub_hive_model.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/query/page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Provider de la [Box] Hive des subs.
final hiveSubBoxProvider = Provider<Box<SubHiveModel>>((ref) => Hive.box<SubHiveModel>('subs'));

/// Provider du [HiveSubRepository].
final subRepositoryProvider = Provider<SubRepository>((ref) => HiveSubRepository(ref.read(hiveSubBoxProvider)));

/// Implémentation de [SubRepository] utilisant Hive comme stockage local.
class HiveSubRepository implements SubRepository {
  /// Crée un [HiveSubRepository].
  HiveSubRepository(this._box);

  final Box<SubHiveModel> _box;

  @override
  Future<Sub> addOne(Sub entity) async {
    try {
      await _box.put(entity.id, SubHiveModel.fromEntity(entity));
      return entity;
    } on HiveError catch (error) {
      throw DatasourceException('HiveSubRepository', error);
    }
  }

  @override
  Future<void> addMany(List<Sub> entities) async {
    try {
      await _box.putAll({for (final entity in entities) entity.id: SubHiveModel.fromEntity(entity)});
    } on HiveError catch (error) {
      throw DatasourceException('HiveSubRepository', error);
    }
  }

  @override
  Future<Sub> updateOne(Sub entity) async {
    try {
      if (!_box.containsKey(entity.id)) {
        throw DatasourceException('HiveSubRepository', 'entity with id "${entity.id}" not found');
      }
      await _box.put(entity.id, SubHiveModel.fromEntity(entity));
      return entity;
    } on DatasourceException {
      rethrow;
    } on HiveError catch (error) {
      throw DatasourceException('HiveSubRepository', error);
    }
  }

  @override
  Future<void> updateMany(List<Sub> entities) async {
    try {
      for (final entity in entities) {
        if (!_box.containsKey(entity.id)) {
          throw DatasourceException('HiveSubRepository', 'entity with id "${entity.id}" not found');
        }
      }
      await _box.putAll({for (final entity in entities) entity.id: SubHiveModel.fromEntity(entity)});
    } on DatasourceException {
      rethrow;
    } on HiveError catch (error) {
      throw DatasourceException('HiveSubRepository', error);
    }
  }

  @override
  Future<Sub?> getUnique(String id) async {
    try {
      return _box.get(id)?.toEntity();
    } on HiveError catch (error) {
      throw DatasourceException('HiveSubRepository', error);
    }
  }

  @override
  Future<List<Sub>> getAll() async {
    try {
      return _box.values.map((model) => model.toEntity()).toList();
    } on HiveError catch (error) {
      throw DatasourceException('HiveSubRepository', error);
    }
  }

  @override
  Future<void> deleteOne(String id) async {
    try {
      await _box.delete(id);
    } on HiveError catch (error) {
      throw DatasourceException('HiveSubRepository', error);
    }
  }

  @override
  Future<void> deleteMany(List<String> ids) async {
    try {
      await _box.deleteAll(ids);
    } on HiveError catch (error) {
      throw DatasourceException('HiveSubRepository', error);
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _box.clear();
    } on HiveError catch (error) {
      throw DatasourceException('HiveSubRepository', error);
    }
  }

  @override
  Future<Page<Sub>> getMany(SubRepositoryParams params) async {
    try {
      final results = _box.values.map((model) => model.toEntity()).toList();
      return Page(items: results, total: results.length);
    } on HiveError catch (error) {
      throw DatasourceException('HiveSubRepository', error);
    }
  }
}
