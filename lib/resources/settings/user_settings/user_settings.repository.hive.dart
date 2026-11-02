import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/settings/user_settings/user_settings.config.dart';
import 'package:bedbug/resources/settings/user_settings/user_settings.entity.dart';
import 'package:bedbug/resources/settings/user_settings/user_settings.model.hive.dart';
import 'package:bedbug/resources/settings/user_settings/user_settings.repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Clé Hive sous laquelle les settings sont persistés.
const String _settingsKey = 'user_settings';

/// Provider de la [Box] Hive des settings.
final hiveUserSettingsBoxProvider = Provider<Box<UserSettingsHiveModel>>(
  (ref) => Hive.box<UserSettingsHiveModel>(userSettingsBoxName),
);

/// Provider du [HiveUserSettingsRepository].
final userSettingsRepositoryProvider = Provider<UserSettingsRepository>((ref) {
  return HiveUserSettingsRepository(ref.read(hiveUserSettingsBoxProvider));
});

/// Implémentation de [UserSettingsRepository] utilisant Hive comme stockage local.
class HiveUserSettingsRepository implements UserSettingsRepository {
  /// Crée un [HiveUserSettingsRepository].
  HiveUserSettingsRepository(this._box);

  final Box<UserSettingsHiveModel> _box;

  @override
  Future<UserSettings?> getUnique(String id) async {
    try {
      return _box.get(_settingsKey)?.toEntity();
    } on HiveError catch (error) {
      throw DatasourceException('HiveUserSettingsRepository', error);
    }
  }

  @override
  Future<UserSettings> addOne(UserSettings entity) async {
    try {
      await _box.put(_settingsKey, UserSettingsHiveModel.fromEntity(entity));
      return entity;
    } on HiveError catch (error) {
      throw DatasourceException('HiveUserSettingsRepository', error);
    }
  }

  @override
  Future<UserSettings> updateOne(UserSettings entity) async {
    try {
      if (!_box.containsKey(_settingsKey)) {
        throw const DatasourceException('HiveUserSettingsRepository', 'settings not found — call addOne first');
      }
      await _box.put(_settingsKey, UserSettingsHiveModel.fromEntity(entity));
      return entity;
    } on DatasourceException {
      rethrow;
    } on HiveError catch (error) {
      throw DatasourceException('HiveUserSettingsRepository', error);
    }
  }
}
