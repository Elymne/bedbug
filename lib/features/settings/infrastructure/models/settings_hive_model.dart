import 'package:bedbug/features/settings/domain/value_objects/user_settings.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/infrastructure/hive_type_ids.dart';
import 'package:hive_ce/hive.dart';

part 'settings_hive_model.g.dart';

/// DTO Hive représentant un [UserSettings] persisté localement.
@HiveType(typeId: HiveTypeIds.settings)
class SettingsHiveModel extends HiveObject {
  /// Crée un [SettingsHiveModel].
  ///
  /// - [blockedUrls] : liste des URLs bloquées.
  /// - [blockedWords] : liste des mots bloqués.
  SettingsHiveModel({
    required this.blockedUrls,
    required this.blockedWords,
  });

  /// Crée un [SettingsHiveModel] depuis un [UserSettings].
  factory SettingsHiveModel.fromEntity(UserSettings entity) {
    return SettingsHiveModel(
      blockedUrls: entity.blockedUrls,
      blockedWords: entity.blockedWords,
    );
  }

  /// Liste des URLs bloquées par l'utilisateur.
  @HiveField(0)
  final List<String> blockedUrls;

  /// Liste des mots bloqués par l'utilisateur.
  @HiveField(1)
  final List<String> blockedWords;

  /// Convertit ce modèle en [UserSettings].
  UserSettings toEntity() {
    try {
      return UserSettings(
        blockedUrls: blockedUrls,
        blockedWords: blockedWords,
      );
    } catch (error) {
      throw DataException('SettingsHiveModel', error);
    }
  }
}
