import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/settings/user_settings/user_settings.config.dart';
import 'package:bedbug/resources/settings/user_settings/user_settings.model.hive.dart';
import 'package:bedbug/resources/settings/user_settings/user_settings.repository.dart';
import 'package:bedbug/resources/settings/user_settings/user_settings.value_object.dart';
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
  Future<UserSettings?> get() async {
    try {
      return _box.get(_settingsKey)?.toEntity();
    } on HiveError catch (error) {
      throw DatasourceException('HiveUserSettingsRepository', error);
    }
  }

  @override
  Future<void> save(UserSettings settings) async {
    try {
      await _box.put(_settingsKey, UserSettingsHiveModel.fromEntity(settings));
    } on HiveError catch (error) {
      throw DatasourceException('HiveUserSettingsRepository', error);
    }
  }
}
