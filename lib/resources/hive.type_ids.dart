import 'package:bedbug/resources/content/comment.model.hive.dart';
import 'package:bedbug/resources/content/content.model.hive.dart';
import 'package:bedbug/resources/content/reaction.model.hive.dart';
import 'package:bedbug/resources/content/storage.model.hive.dart';
import 'package:bedbug/resources/content/trust_settings.model.hive.dart';
import 'package:bedbug/resources/exchange/exchange_log.model.hive.dart';
import 'package:bedbug/resources/exchange/keychain.model.hive.dart';
import 'package:bedbug/resources/settings/settings.model.hive.dart';
import 'package:bedbug/resources/signature/signature.model.hive.dart';

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
