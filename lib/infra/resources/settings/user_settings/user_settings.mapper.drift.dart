import 'package:bedbug/infra/resources/data.exception.dart';
import 'package:bedbug/infra/resources/drift.config.dart';
import 'package:bedbug/infra/resources/drift.database.dart';
import 'package:bedbug/infra/resources/settings/user_settings/user_settings.value_object.dart';
import 'package:drift/drift.dart';

/// Conversion entre les [UserSettings] et la ligne unique de la table `user_settings_store`.
abstract final class UserSettingsDriftMapper {
  /// Reconstruit les réglages de la ligne.
  ///
  /// Lève une [DataException] si la ligne ne peut pas être convertie.
  ///
  /// [row] : ligne lue dans la table `user_settings_store`.
  static UserSettings toEntity(UserSettingsRow row) {
    try {
      return UserSettings(
        blockedUrls: row.blockedUrls,
        blockedWords: row.blockedWords,
        isAnonymousByDefault: row.isAnonymousByDefault,
        isExchangeEnabled: row.isExchangeEnabled,
      );
    } catch (error) {
      throw DataException('UserSettingsDriftMapper', error);
    }
  }

  /// Construit la ligne unique à écrire pour des réglages, toujours sous [singleRowId].
  ///
  /// [entity] : réglages à écrire.
  static UserSettingsStoreCompanion toCompanion(UserSettings entity) {
    return UserSettingsStoreCompanion.insert(
      id: const Value(singleRowId),
      blockedUrls: entity.blockedUrls,
      blockedWords: entity.blockedWords,
      isAnonymousByDefault: entity.isAnonymousByDefault,
      isExchangeEnabled: entity.isExchangeEnabled,
    );
  }
}
