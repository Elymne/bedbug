import 'package:bedbug/features/content/infrastructure/models/comment_hive_model.dart';
import 'package:bedbug/features/content/infrastructure/models/content_hive_model.dart';
import 'package:bedbug/features/content/infrastructure/models/storage_hive_model.dart';
import 'package:bedbug/features/content/infrastructure/models/sub_hive_model.dart';
import 'package:bedbug/features/discovery/infrastructure/models/keychain_hive_model.dart';
import 'package:bedbug/features/settings/infrastructure/models/settings_hive_model.dart';
import 'package:bedbug/features/user/infrastructure/models/user_hive_model.dart';

/// Registre centralisé des typeId Hive utilisés dans l'application.
///
/// Chaque valeur doit être unique. Ne jamais réutiliser un typeId supprimé.
class HiveTypeIds {
  HiveTypeIds._();

  /// TypeId de [UserHiveModel].
  static const int user = 0;

  /// TypeId de [ContentHiveModel].
  static const int content = 1;

  /// TypeId de [CommentHiveModel].
  static const int comment = 2;

  /// TypeId de [SubHiveModel].
  static const int sub = 3;

  /// TypeId de [KeychainHiveModel].
  static const int keychain = 4;

  /// TypeId de [PrivateKeyHiveModel].
  static const int privateKey = 5;

  /// TypeId de [StorageHiveModel].
  static const int storage = 6;

  /// TypeId de [SettingsHiveModel].
  static const int settings = 7;
}
