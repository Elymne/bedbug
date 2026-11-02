import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/hive.type_ids.dart';
import 'package:bedbug/resources/settings/user_settings/user_settings.entity.dart';
import 'package:hive_ce/hive.dart';

part 'user_settings.model.hive.g.dart';

/// DTO Hive représentant un [UserSettings] persisté localement.
@HiveType(typeId: HiveTypeIds.userSettings)
class UserSettingsHiveModel extends HiveObject {
  /// Crée un [UserSettingsHiveModel].
  ///
  /// - [id] : identifiant de l'enregistrement unique.
  /// - [createdAt] : date de création.
  /// - [updatedAt] : date de dernière mise à jour.
  /// - [blockedUrls] : liste des URLs bloquées.
  /// - [blockedWords] : liste des mots bloqués.
  /// - [isAnonymousByDefault] : publication anonyme par défaut des nouveaux contenus.
  /// - [isExchangeEnabled] : échange avec les téléphones proches activé.
  UserSettingsHiveModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.blockedUrls,
    required this.blockedWords,
    required this.isAnonymousByDefault,
    required this.isExchangeEnabled,
  });

  /// Crée un [UserSettingsHiveModel] depuis un [UserSettings].
  ///
  /// - [entity] : réglages à persister.
  factory UserSettingsHiveModel.fromEntity(UserSettings entity) {
    return UserSettingsHiveModel(
      id: entity.id,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      blockedUrls: entity.blockedUrls,
      blockedWords: entity.blockedWords,
      isAnonymousByDefault: entity.isAnonymousByDefault,
      isExchangeEnabled: entity.isExchangeEnabled,
    );
  }

  /// Identifiant de l'enregistrement unique.
  @HiveField(0)
  final String id;

  /// Date de création.
  @HiveField(1)
  final DateTime createdAt;

  /// Date de dernière mise à jour.
  @HiveField(2)
  final DateTime updatedAt;

  /// Liste des URLs bloquées par l'utilisateur.
  @HiveField(3)
  final List<String> blockedUrls;

  /// Liste des mots bloqués par l'utilisateur.
  @HiveField(4)
  final List<String> blockedWords;

  /// Publication anonyme par défaut des nouveaux contenus.
  @HiveField(5)
  final bool isAnonymousByDefault;

  /// Échange avec les téléphones proches activé.
  @HiveField(6)
  final bool isExchangeEnabled;

  /// Convertit ce modèle en [UserSettings].
  ///
  /// Lève une [DataException] si la donnée lue est invalide.
  UserSettings toEntity() {
    try {
      return UserSettings(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt,
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
