import 'package:bedbug/features/discovery/domain/entities/keychain.dart';
import 'package:bedbug/features/discovery/domain/repositories/keychain_repository.dart';
import 'package:bedbug/features/discovery/infrastructure/models/keychain_hive_model.dart';
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
    await _box.put(entity.id, KeychainHiveModel.fromEntity(entity));
    return entity;
  }

  @override
  Future<Keychain> updateOne(Keychain entity) async {
    await _box.put(entity.id, KeychainHiveModel.fromEntity(entity));
    return entity;
  }

  @override
  Future<Keychain?> getUnique(String id) async {
    return _box.get(id)?.toEntity();
  }

  @override
  Future<List<Keychain>> getAll() async {
    return _box.values.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> deleteOne(String id) async {
    await _box.delete(id);
  }

  @override
  Future<Page<Keychain>> getMany(KeychainRepositoryParams params) async {
    var results = _box.values.map((model) => model.toEntity()).toList();

    if (params.subId != null) {
      results = results
          .where((keychain) => keychain.subId == params.subId)
          .toList();
    }

    return Page(items: results, total: results.length);
  }
}
