import 'package:bedbug/features/trust/domain/object_values/trust_settings.dart';
import 'package:bedbug/features/trust/domain/repositories/trust_settings_repository.dart';
import 'package:bedbug/features/trust/infrastructure/models/trust_settings_hive_model.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Nom de la box Hive des réglages de confiance.
const String trustSettingsBoxName = 'trust_settings';

/// Clé Hive sous laquelle les réglages de confiance sont persistés.
const String _settingsKey = 'trust_settings';

/// Provider de la [Box] Hive des réglages de confiance.
final hiveTrustSettingsBoxProvider = Provider<Box<TrustSettingsHiveModel>>((ref) {
  return Hive.box<TrustSettingsHiveModel>(trustSettingsBoxName);
});

/// Provider du [TrustSettingsRepository].
final trustSettingsRepositoryProvider = Provider<TrustSettingsRepository>((ref) {
  return HiveTrustSettingsRepository(ref.read(hiveTrustSettingsBoxProvider));
});

/// Implémentation de [TrustSettingsRepository] utilisant Hive comme stockage local.
class HiveTrustSettingsRepository implements TrustSettingsRepository {
  /// Crée un [HiveTrustSettingsRepository].
  HiveTrustSettingsRepository(this._box);

  final Box<TrustSettingsHiveModel> _box;

  @override
  Future<TrustSettings?> get() async {
    try {
      return _box.get(_settingsKey)?.toEntity();
    } on HiveError catch (error) {
      throw DatasourceException('HiveTrustSettingsRepository', error);
    }
  }

  @override
  Future<void> save(TrustSettings settings) async {
    try {
      await _box.put(_settingsKey, TrustSettingsHiveModel.fromEntity(settings));
    } on HiveError catch (error) {
      throw DatasourceException('HiveTrustSettingsRepository', error);
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _box.delete(_settingsKey);
    } on HiveError catch (error) {
      throw DatasourceException('HiveTrustSettingsRepository', error);
    }
  }
}
