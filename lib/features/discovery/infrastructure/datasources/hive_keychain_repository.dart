import 'package:bedbug/features/discovery/domain/entities/keychain.dart';
import 'package:bedbug/features/discovery/domain/repositories/keychain_repository.dart';
import 'package:bedbug/features/discovery/infrastructure/models/keychain_hive_model.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/query/page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Provider de la [Box] Hive des portefeuilles de clés.
final hiveKeychainBoxProvider = Provider<Box<KeychainHiveModel>>(
  (ref) => Hive.box<KeychainHiveModel>('keychains'),
);

/// Provider du [HiveKeychainRepository].
final keychainRepositoryProvider = Provider<KeychainRepository>(
  (ref) => HiveKeychainRepository(ref.read(hiveKeychainBoxProvider)),
);

/// Implémentation de [KeychainRepository] utilisant Hive comme stockage local.
class HiveKeychainRepository implements KeychainRepository {
  /// Crée un [HiveKeychainRepository].
  HiveKeychainRepository(this._box);

  final Box<KeychainHiveModel> _box;

  @override
  Future<Keychain> addOne(Keychain entity) async {
    try {
      await _box.put(entity.id, KeychainHiveModel.fromEntity(entity));
      return entity;
    } on HiveError catch (error) {
      throw DatasourceException('HiveKeychainRepository', error);
    }
  }

  @override
  Future<void> addMany(List<Keychain> entities) async {
    try {
      await _box.putAll({
        for (final entity in entities) entity.id: KeychainHiveModel.fromEntity(entity),
      });
    } on HiveError catch (error) {
      throw DatasourceException('HiveKeychainRepository', error);
    }
  }

  @override
  Future<Keychain> updateOne(Keychain entity) async {
    try {
      if (!_box.containsKey(entity.id)) {
        throw DatasourceException('HiveKeychainRepository', 'entity with id "${entity.id}" not found');
      }
      await _box.put(entity.id, KeychainHiveModel.fromEntity(entity));
      return entity;
    } on DatasourceException {
      rethrow;
    } on HiveError catch (error) {
      throw DatasourceException('HiveKeychainRepository', error);
    }
  }

  @override
  Future<void> updateMany(List<Keychain> entities) async {
    try {
      for (final entity in entities) {
        if (!_box.containsKey(entity.id)) {
          throw DatasourceException('HiveKeychainRepository', 'entity with id "${entity.id}" not found');
        }
      }
      await _box.putAll({
        for (final entity in entities) entity.id: KeychainHiveModel.fromEntity(entity),
      });
    } on DatasourceException {
      rethrow;
    } on HiveError catch (error) {
      throw DatasourceException('HiveKeychainRepository', error);
    }
  }

  @override
  Future<Keychain?> getUnique(String id) async {
    try {
      return _box.get(id)?.toEntity();
    } on HiveError catch (error) {
      throw DatasourceException('HiveKeychainRepository', error);
    }
  }

  @override
  Future<List<Keychain>> getAll() async {
    try {
      return _box.values.map((model) => model.toEntity()).toList();
    } on HiveError catch (error) {
      throw DatasourceException('HiveKeychainRepository', error);
    }
  }

  @override
  Future<void> deleteOne(String id) async {
    try {
      await _box.delete(id);
    } on HiveError catch (error) {
      throw DatasourceException('HiveKeychainRepository', error);
    }
  }

  @override
  Future<void> deleteMany(List<String> ids) async {
    try {
      await _box.deleteAll(ids);
    } on HiveError catch (error) {
      throw DatasourceException('HiveKeychainRepository', error);
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _box.clear();
    } on HiveError catch (error) {
      throw DatasourceException('HiveKeychainRepository', error);
    }
  }

  @override
  Future<Page<Keychain>> getMany(KeychainRepositoryParams params) async {
    try {
      var results = _box.values.map((model) => model.toEntity()).toList();

      if (params.subId != null) {
        results = results
            .where((keychain) => keychain.subId == params.subId)
            .toList();
      }

      return Page(items: results, total: results.length);
    } on HiveError catch (error) {
      throw DatasourceException('HiveKeychainRepository', error);
    }
  }
}
