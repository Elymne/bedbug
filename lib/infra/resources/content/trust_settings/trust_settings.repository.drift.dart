import 'package:bedbug/infra/resources/content/trust_settings/trust_settings.mapper.drift.dart';
import 'package:bedbug/infra/resources/content/trust_settings/trust_settings.repository.dart';
import 'package:bedbug/infra/resources/content/trust_settings/trust_settings.value_object.dart';
import 'package:bedbug/infra/resources/drift.config.dart';
import 'package:bedbug/infra/resources/drift.database.dart';
import 'package:bedbug/infra/resources/drift.guard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [DriftTrustSettingsRepository].
final trustSettingsRepositoryProvider = Provider<TrustSettingsRepository>((ref) {
  return DriftTrustSettingsRepository(ref.read(appDatabaseProvider));
});

/// Implémentation de [TrustSettingsRepository] stockant les réglages dans la ligne unique de `trust_settings_store`.
class DriftTrustSettingsRepository implements TrustSettingsRepository {
  /// Crée un [DriftTrustSettingsRepository].
  ///
  /// - [_database] : base SQLite de l'app.
  DriftTrustSettingsRepository(this._database);

  /// Base SQLite de l'app.
  final AppDatabase _database;

  /// Lit la ligne [singleRowId], absente tant que l'utilisateur n'a rien modifié.
  @override
  Future<TrustSettings?> get() async {
    return guardDrift('DriftTrustSettingsRepository', () async {
      final query = _database.select(_database.trustSettingsStore)..where((row) => row.id.equals(singleRowId));
      final row = await query.getSingleOrNull();
      if (row == null) {
        return null;
      }
      return TrustSettingsDriftMapper.toEntity(row);
    });
  }

  /// Écrit [settings] dans la ligne [singleRowId], créée au premier enregistrement puis remplacée.
  ///
  /// - [settings] : réglages à enregistrer.
  @override
  Future<void> save(TrustSettings settings) async {
    await guardDrift('DriftTrustSettingsRepository', () async {
      await _database
          .into(_database.trustSettingsStore)
          .insertOnConflictUpdate(TrustSettingsDriftMapper.toCompanion(settings));
    });
  }

  /// Supprime la ligne [singleRowId] : [get] retourne alors `null`, et l'app revient aux réglages par défaut.
  @override
  Future<void> clear() async {
    await guardDrift('DriftTrustSettingsRepository', () async {
      await (_database.delete(_database.trustSettingsStore)..where((row) => row.id.equals(singleRowId))).go();
    });
  }
}
