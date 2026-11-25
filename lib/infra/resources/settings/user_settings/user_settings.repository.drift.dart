import 'package:bedbug/infra/resources/drift.config.dart';
import 'package:bedbug/infra/resources/drift.database.dart';
import 'package:bedbug/infra/resources/drift.guard.dart';
import 'package:bedbug/infra/resources/settings/user_settings/user_settings.mapper.drift.dart';
import 'package:bedbug/infra/resources/settings/user_settings/user_settings.repository.dart';
import 'package:bedbug/infra/resources/settings/user_settings/user_settings.value_object.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [DriftUserSettingsRepository].
final userSettingsRepositoryProvider = Provider<UserSettingsRepository>((ref) {
  return DriftUserSettingsRepository(ref.read(appDatabaseProvider));
});

/// Implémentation de [UserSettingsRepository] stockant les réglages dans la ligne unique de `user_settings_store`.
class DriftUserSettingsRepository implements UserSettingsRepository {
  /// Crée un [DriftUserSettingsRepository].
  ///
  /// - [_database] : base SQLite de l'app.
  DriftUserSettingsRepository(this._database);

  /// Base SQLite de l'app.
  final AppDatabase _database;

  /// Lit la ligne [singleRowId], absente tant que les réglages n'ont jamais été enregistrés.
  @override
  Future<UserSettings?> get() async {
    return guardDrift('DriftUserSettingsRepository', () async {
      final query = _database.select(_database.userSettingsStore)..where((row) => row.id.equals(singleRowId));
      final row = await query.getSingleOrNull();
      if (row == null) {
        return null;
      }
      return UserSettingsDriftMapper.toEntity(row);
    });
  }

  /// Écrit [settings] dans la ligne [singleRowId], créée au premier enregistrement puis remplacée.
  ///
  /// - [settings] : réglages à enregistrer.
  @override
  Future<void> save(UserSettings settings) async {
    await guardDrift('DriftUserSettingsRepository', () async {
      await _database
          .into(_database.userSettingsStore)
          .insertOnConflictUpdate(UserSettingsDriftMapper.toCompanion(settings));
    });
  }
}
