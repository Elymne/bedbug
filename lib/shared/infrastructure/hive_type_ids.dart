import 'package:bedbug/features/content/infrastructure/models/comment_hive_model.dart';
import 'package:bedbug/features/content/infrastructure/models/content_hive_model.dart';
import 'package:bedbug/features/content/infrastructure/models/reaction_hive_model.dart';
import 'package:bedbug/features/content/infrastructure/models/storage_hive_model.dart';
import 'package:bedbug/features/content/infrastructure/models/trust_settings_hive_model.dart';
import 'package:bedbug/features/exchange/infrastructure/models/exchange_log_hive_model.dart';
import 'package:bedbug/features/exchange/infrastructure/models/keychain_hive_model.dart';
import 'package:bedbug/features/settings/infrastructure/models/settings_hive_model.dart';
import 'package:bedbug/features/signature/infrastructure/models/signature_hive_model.dart';

/// Registre centralisé des typeId Hive utilisés dans l'application.
///
/// Chaque valeur doit être unique. Ne jamais réutiliser un typeId supprimé.
class HiveTypeIds {
  HiveTypeIds._();

  /// TypeId de [SignatureHiveModel].
  static const int signature = 0;

  /// TypeId de [ContentHiveModel].
  static const int content = 1;

  /// TypeId de [CommentHiveModel].
  static const int comment = 2;

  // TypeId 3 : anciennement `SubHiveModel` (supprimé). Ne pas réutiliser.

  /// TypeId de [KeychainHiveModel].
  static const int keychain = 4;

  /// TypeId de [PrivateKeyHiveModel].
  static const int privateKey = 5;

  /// TypeId de [StorageHiveModel].
  static const int storage = 6;

  /// TypeId de [SettingsHiveModel].
  static const int settings = 7;

  /// TypeId de [ReactionHiveModel].
  static const int reaction = 8;

  /// TypeId de [TrustSettingsHiveModel].
  static const int trustSettings = 9;

  /// TypeId de [ExchangeLogHiveModel].
  static const int exchangeLog = 10;
}
