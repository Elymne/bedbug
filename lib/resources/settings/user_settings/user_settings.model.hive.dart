import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/hive.type_ids.dart';
import 'package:bedbug/resources/settings/user_settings/user_settings.value_object.dart';
import 'package:hive_ce/hive.dart';

part 'user_settings.model.hive.g.dart';

/// DTO Hive représentant un [UserSettings] persisté localement.
@HiveType(typeId: HiveTypeIds.userSettings)
class UserSettingsHiveModel extends HiveObject {
  /// Crée un [UserSettingsHiveModel].
  ///
  /// - [blockedUrls] : liste des URLs bloquées.
  /// - [blockedWords] : liste des mots bloqués.
  /// - [isAnonymousByDefault] : publication anonyme par défaut des nouveaux contenus.
  /// - [isExchangeEnabled] : échange avec les téléphones proches activé.
  UserSettingsHiveModel({
    required this.blockedUrls,
    required this.blockedWords,
    required this.isAnonymousByDefault,
    required this.isExchangeEnabled,
  });

  /// Crée un [UserSettingsHiveModel] depuis un [UserSettings].
  ///
  /// - [settings] : réglages à persister.
  factory UserSettingsHiveModel.fromEntity(UserSettings settings) {
    return UserSettingsHiveModel(
      blockedUrls: settings.blockedUrls,
      blockedWords: settings.blockedWords,
      isAnonymousByDefault: settings.isAnonymousByDefault,
      isExchangeEnabled: settings.isExchangeEnabled,
    );
  }

  /// Liste des URLs bloquées par l'utilisateur.
  @HiveField(0)
  final List<String> blockedUrls;

  /// Liste des mots bloqués par l'utilisateur.
  @HiveField(1)
  final List<String> blockedWords;

  /// Publication anonyme par défaut des nouveaux contenus.
  @HiveField(2)
  final bool isAnonymousByDefault;

  /// Échange avec les téléphones proches activé.
  @HiveField(3)
  final bool isExchangeEnabled;

  /// Convertit ce modèle en [UserSettings].
  ///
  /// Lève une [DataException] si la donnée lue est invalide.
  UserSettings toEntity() {
    try {
      return UserSettings(
        blockedUrls: blockedUrls,
        blockedWords: blockedWords,
        isAnonymousByDefault: isAnonymousByDefault,
        isExchangeEnabled: isExchangeEnabled,
      );
    } catch (error) {
      throw DataException('UserSettingsHiveModel', error);
    }
  }
}
