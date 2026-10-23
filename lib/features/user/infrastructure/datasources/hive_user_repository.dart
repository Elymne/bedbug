import 'package:bedbug/features/user/domain/entities/user.dart';
import 'package:bedbug/features/user/domain/repositories/user_repository.dart';
import 'package:bedbug/features/user/infrastructure/models/user_hive_model.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Provider de la [Box] Hive des utilisateurs.
final hiveUserBoxProvider = Provider<Box<UserHiveModel>>((ref) => Hive.box<UserHiveModel>('users'));

/// Provider du [HiveUserRepository].
final userRepositoryProvider = Provider<UserRepository>((ref) => HiveUserRepository(ref.read(hiveUserBoxProvider)));

/// Implémentation de [UserRepository] utilisant Hive comme stockage local.
class HiveUserRepository implements UserRepository {
  /// Crée un [HiveUserRepository].
  HiveUserRepository(this._box);

  final Box<UserHiveModel> _box;

  @override
  Future<User?> getLocal() async {
    try {
      return _box.get(localUserId)?.toEntity();
    } on HiveError catch (error) {
      throw DatasourceException('HiveUserRepository', error);
    }
  }

  @override
  Future<User> saveLocal(User entity) async {
    try {
      await _box.put(localUserId, UserHiveModel.fromEntity(entity));
      return entity;
    } on HiveError catch (error) {
      throw DatasourceException('HiveUserRepository', error);
    }
  }
}
