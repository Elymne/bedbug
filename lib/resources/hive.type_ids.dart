import 'package:bedbug/resources/content/comment/comment.model.hive.dart';
import 'package:bedbug/resources/content/content/content.model.hive.dart';
import 'package:bedbug/resources/content/reaction/reaction.model.hive.dart';
import 'package:bedbug/resources/content/seen_content/seen_content.model.hive.dart';
import 'package:bedbug/resources/content/storage/storage.model.hive.dart';
import 'package:bedbug/resources/content/trust_settings/trust_settings.model.hive.dart';
import 'package:bedbug/resources/content/viewed_content/viewed_content.model.hive.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.model.hive.dart';
import 'package:bedbug/resources/exchange/exchange_log/exchange_log.model.hive.dart';
import 'package:bedbug/resources/exchange/keychain/keychain.model.hive.dart';
import 'package:bedbug/resources/settings/settings/settings.model.hive.dart';
import 'package:bedbug/resources/signature/signature/signature.model.hive.dart';

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

  /// TypeId de [ErrorLogHiveModel].
  static const int errorLog = 11;

  /// TypeId de [ViewedContentHiveModel].
  static const int viewedContent = 12;

  /// TypeId de [SeenContentHiveModel].
  static const int seenContent = 13;
}
