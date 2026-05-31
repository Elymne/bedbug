import 'package:bedbug/features/settings/domain/repositories/settings_repository.dart';
import 'package:bedbug/features/settings/domain/value_objects/user_settings.dart';
import 'package:bedbug/features/settings/infrastructure/models/settings_hive_model.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/query/page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Clé Hive sous laquelle les settings sont persistés.
const String _settingsKey = 'user_settings';

/// Provider de la [Box] Hive des settings.
final hiveSettingsBoxProvider = Provider<Box<SettingsHiveModel>>((ref) => Hive.box<SettingsHiveModel>('settings'));

/// Provider du [HiveSettingsRepository].
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => HiveSettingsRepository(ref.read(hiveSettingsBoxProvider)),
);

/// Implémentation de [SettingsRepository] utilisant Hive comme stockage local.
class HiveSettingsRepository implements SettingsRepository {
  /// Crée un [HiveSettingsRepository].
  HiveSettingsRepository(this._box);

  final Box<SettingsHiveModel> _box;

  @override
  Future<UserSettings?> getUnique(String id) async {
    try {
      return _box.get(_settingsKey)?.toEntity();
    } on HiveError catch (error) {
      throw DatasourceException('HiveSettingsRepository', error);
    }
  }

  @override
  Future<UserSettings> addOne(UserSettings entity) async {
    try {
      await _box.put(_settingsKey, SettingsHiveModel.fromEntity(entity));
      return entity;
    } on HiveError catch (error) {
      throw DatasourceException('HiveSettingsRepository', error);
    }
  }

  @override
  Future<UserSettings> updateOne(UserSettings entity) async {
    try {
      if (!_box.containsKey(_settingsKey)) {
        throw const DatasourceException('HiveSettingsRepository', 'settings not found — call addOne first');
      }
      await _box.put(_settingsKey, SettingsHiveModel.fromEntity(entity));
      return entity;
    } on DatasourceException {
      rethrow;
    } on HiveError catch (error) {
      throw DatasourceException('HiveSettingsRepository', error);
    }
  }

  @override
  Future<void> addMany(List<UserSettings> entities) {
    throw UnimplementedError('addMany is not supported');
  }

  @override
  Future<void> updateMany(List<UserSettings> entities) {
    throw UnimplementedError('updateMany is not supported');
  }

  @override
  Future<List<UserSettings>> getAll() {
    throw UnimplementedError('getAll is not supported');
  }

  @override
  Future<void> deleteOne(String id) {
    throw UnimplementedError('deleteOne is not supported');
  }

  @override
  Future<void> deleteMany(List<String> ids) {
    throw UnimplementedError('deleteMany is not supported');
  }

  @override
  Future<void> deleteAll() {
    throw UnimplementedError('deleteAll is not supported');
  }

  @override
  Future<Page<UserSettings>> getMany(SettingsRepositoryParams params) {
    throw UnimplementedError('getMany is not supported');
  }
}
