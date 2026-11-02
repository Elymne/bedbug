import 'dart:typed_data';

import 'package:bedbug/hive_registrar.g.dart';
import 'package:bedbug/resources/content/comment/comment.config.dart';
import 'package:bedbug/resources/content/comment/comment.model.hive.dart';
import 'package:bedbug/resources/content/content/content.config.dart';
import 'package:bedbug/resources/content/content/content.model.hive.dart';
import 'package:bedbug/resources/content/drawing/drawing.config.dart';
import 'package:bedbug/resources/content/reaction/reaction.config.dart';
import 'package:bedbug/resources/content/reaction/reaction.model.hive.dart';
import 'package:bedbug/resources/content/seen_content/seen_content.config.dart';
import 'package:bedbug/resources/content/seen_content/seen_content.model.hive.dart';
import 'package:bedbug/resources/content/storage/storage.config.dart';
import 'package:bedbug/resources/content/storage/storage.model.hive.dart';
import 'package:bedbug/resources/content/trust_settings/trust_settings.config.dart';
import 'package:bedbug/resources/content/trust_settings/trust_settings.model.hive.dart';
import 'package:bedbug/resources/content/viewed_content/viewed_content.config.dart';
import 'package:bedbug/resources/content/viewed_content/viewed_content.model.hive.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.config.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.model.hive.dart';
import 'package:bedbug/resources/exchange/exchange_log/exchange_log.config.dart';
import 'package:bedbug/resources/exchange/exchange_log/exchange_log.model.hive.dart';
import 'package:bedbug/resources/exchange/keychain/keychain.config.dart';
import 'package:bedbug/resources/exchange/keychain/keychain.model.hive.dart';
import 'package:bedbug/resources/settings/settings/settings.config.dart';
import 'package:bedbug/resources/settings/settings/settings.model.hive.dart';
import 'package:bedbug/resources/signature/signature/signature.config.dart';
import 'package:bedbug/resources/signature/signature/signature.model.hive.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Initialise Hive, enregistre les adapters et ouvre toutes les boxes.
///
/// À appeler une seule fois au démarrage de l'application, avant tout
/// accès aux repositories.
Future<void> initHive() async {
  await Hive.initFlutter();
  Hive.registerAdapters();
  await Future.wait([
    Hive.openBox<SignatureHiveModel>(signatureBoxName),
    Hive.openBox<ContentHiveModel>(contentBoxName),
    Hive.openBox<CommentHiveModel>(commentBoxName),
    Hive.openBox<ReactionHiveModel>(reactionBoxName),
    Hive.openBox<KeychainHiveModel>(keychainBoxName),
    Hive.openBox<StorageHiveModel>(storageBoxName),
    Hive.openBox<SettingsHiveModel>(settingsBoxName),
    Hive.openBox<Uint8List>(drawingDraftBoxName),
    Hive.openBox<TrustSettingsHiveModel>(trustSettingsBoxName),
    Hive.openBox<SeenContentHiveModel>(seenContentBoxName),
    Hive.openBox<ViewedContentHiveModel>(viewedContentBoxName),
    Hive.openBox<ExchangeLogHiveModel>(exchangeLogBoxName),
    Hive.openBox<ErrorLogHiveModel>(errorLogBoxName),
  ]);
}
