import 'package:bedbug/features/user/domain/entities/user.dart';
import 'package:bedbug/features/user/domain/repositories/user_repository.dart';
import 'package:bedbug/features/user/infrastructure/models/user_hive_model.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/query/page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Provider de la [Box] Hive des utilisateurs.
final hiveUserBoxProvider = Provider<Box<UserHiveModel>>(
  (ref) => Hive.box<UserHiveModel>('users'),
);

/// Provider du [HiveUserRepository].
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => HiveUserRepository(ref.read(hiveUserBoxProvider)),
);

/// Implémentation de [UserRepository] utilisant Hive comme stockage local.
class HiveUserRepository implements UserRepository {
  /// Crée un [HiveUserRepository].
  HiveUserRepository(this._box);

  final Box<UserHiveModel> _box;

  @override
  Future<User> addOne(User entity) async {
    try {
      await _box.put(entity.id, UserHiveModel.fromEntity(entity));
      return entity;
    } on HiveError catch (error) {
      throw DatasourceException('HiveUserRepository', error);
    }
  }

  @override
  Future<User> updateOne(User entity) async {
    try {
      await _box.put(entity.id, UserHiveModel.fromEntity(entity));
      return entity;
    } on HiveError catch (error) {
      throw DatasourceException('HiveUserRepository', error);
    }
  }

  @override
  Future<User?> getUnique(String id) async {
    try {
      return _box.get(id)?.toEntity();
    } on HiveError catch (error) {
      throw DatasourceException('HiveUserRepository', error);
    }
  }

  @override
  Future<List<User>> getAll() async {
    try {
      return _box.values.map((model) => model.toEntity()).toList();
    } on HiveError catch (error) {
      throw DatasourceException('HiveUserRepository', error);
    }
  }

  @override
  Future<void> deleteOne(String id) async {
    try {
      await _box.delete(id);
    } on HiveError catch (error) {
      throw DatasourceException('HiveUserRepository', error);
    }
  }

  @override
  Future<Page<User>> getMany(UserRepositoryParams params) async {
    try {
      var results = _box.values.map((model) => model.toEntity()).toList();

      if (params.pseudo != null) {
        results = results
            .where(
              (user) => user.pseudo.toLowerCase().contains(
                params.pseudo!.toLowerCase(),
              ),
            )
            .toList();
      }

      return Page(items: results, total: results.length);
    } on HiveError catch (error) {
      throw DatasourceException('HiveUserRepository', error);
    }
  }
}
