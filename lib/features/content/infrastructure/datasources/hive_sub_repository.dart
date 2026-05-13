import 'package:bedbug/features/content/domain/entities/sub.dart';
import 'package:bedbug/features/content/domain/repositories/sub_repository.dart';
import 'package:bedbug/features/content/infrastructure/models/sub_hive_model.dart';
import 'package:bedbug/shared/query/page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Provider de la [Box] Hive des subs.
final hiveSubBoxProvider = Provider<Box<SubHiveModel>>(
  (ref) => Hive.box<SubHiveModel>('subs'),
);

/// Provider du [HiveSubRepository].
final subRepositoryProvider = Provider<SubRepository>(
  (ref) => HiveSubRepository(ref.read(hiveSubBoxProvider)),
);

/// Implémentation de [SubRepository] utilisant Hive comme stockage local.
class HiveSubRepository implements SubRepository {
  /// Crée un [HiveSubRepository].
  HiveSubRepository(this._box);

  final Box<SubHiveModel> _box;

  @override
  Future<Sub> addOne(Sub entity) async {
    await _box.put(entity.id, SubHiveModel.fromEntity(entity));
    return entity;
  }

  @override
  Future<Sub> updateOne(Sub entity) async {
    await _box.put(entity.id, SubHiveModel.fromEntity(entity));
    return entity;
  }

  @override
  Future<Sub?> getUnique(String id) async {
    return _box.get(id)?.toEntity();
  }

  @override
  Future<List<Sub>> getAll() async {
    return _box.values.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> deleteOne(String id) async {
    await _box.delete(id);
  }

  @override
  Future<Page<Sub>> getMany(SubRepositoryParams params) async {
    final results = _box.values.map((model) => model.toEntity()).toList();
    return Page(items: results, total: results.length);
  }
}
