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
import 'package:bedbug/resources/hive.type_ids.dart';
import 'package:bedbug/resources/settings/user_settings/user_settings.config.dart';
import 'package:bedbug/resources/settings/user_settings/user_settings.model.hive.dart';
import 'package:bedbug/resources/signature/signature/signature.config.dart';
import 'package:bedbug/resources/signature/signature/signature.model.hive.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Initialise Hive, enregistre les adapters et ouvre toutes les boxes.
///
/// À appeler au démarrage de l'application, avant tout accès aux
/// repositories. Peut être rappelée (après un `Hive.deleteFromDisk`, pour
/// repartir d'une base vide) : les adapters ne sont enregistrés qu'une fois.
///
/// - [subDirectory] : dossier des données, `null` pour celui de l'app. Le smoke test sur téléphone en utilise un à
///   part, pour ne jamais toucher aux données de l'utilisateur.
Future<void> initHive({String? subDirectory}) async {
  await Hive.initFlutter(subDirectory);
  if (!Hive.isAdapterRegistered(HiveTypeIds.signature)) {
    Hive.registerAdapters();
  }
  await Future.wait([
    Hive.openBox<SignatureHiveModel>(signatureBoxName),
    Hive.openBox<ContentHiveModel>(contentBoxName),
    Hive.openBox<CommentHiveModel>(commentBoxName),
    Hive.openBox<ReactionHiveModel>(reactionBoxName),
    Hive.openBox<KeychainHiveModel>(keychainBoxName),
    Hive.openBox<StorageHiveModel>(storageBoxName),
    Hive.openBox<UserSettingsHiveModel>(userSettingsBoxName),
    Hive.openBox<Uint8List>(drawingDraftBoxName),
    Hive.openBox<TrustSettingsHiveModel>(trustSettingsBoxName),
    Hive.openBox<SeenContentHiveModel>(seenContentBoxName),
    Hive.openBox<ViewedContentHiveModel>(viewedContentBoxName),
    Hive.openBox<ExchangeLogHiveModel>(exchangeLogBoxName),
    Hive.openBox<ErrorLogHiveModel>(errorLogBoxName),
  ]);
}
