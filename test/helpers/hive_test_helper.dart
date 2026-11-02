import 'dart:io';
import 'dart:typed_data';

import 'package:bedbug/hive_registrar.g.dart';
import 'package:bedbug/resources/content/comment/comment.model.hive.dart';
import 'package:bedbug/resources/content/content/content.model.hive.dart';
import 'package:bedbug/resources/content/drawing/drawing_draft.repository.hive.dart';
import 'package:bedbug/resources/content/reaction/reaction.model.hive.dart';
import 'package:bedbug/resources/content/seen_content/seen_content.repository.hive.dart';
import 'package:bedbug/resources/content/storage/storage.model.hive.dart';
import 'package:bedbug/resources/content/trust_settings/trust_settings.model.hive.dart';
import 'package:bedbug/resources/content/trust_settings/trust_settings.repository.hive.dart';
import 'package:bedbug/resources/content/viewed_content/viewed_content.repository.hive.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.model.hive.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.hive.dart';
import 'package:bedbug/resources/exchange/exchange_log/exchange_log.model.hive.dart';
import 'package:bedbug/resources/exchange/exchange_log/exchange_log.repository.hive.dart';
import 'package:bedbug/resources/exchange/keychain/keychain.model.hive.dart';
import 'package:bedbug/resources/settings/settings/settings.model.hive.dart';
import 'package:bedbug/resources/signature/signature/signature.model.hive.dart';
import 'package:hive_ce/hive.dart';

/// Ouvre Hive sur un répertoire temporaire réel du disque, avec toutes les
/// boxes de l'application, pour les tests d'intégration.
///
/// Retourne le répertoire temporaire créé, à passer à [closeTestHive] pour
/// le nettoyer après le test.
bool _areAdaptersRegistered = false;

Future<Directory> openTestHive() async {
  final tempDir = await Directory.systemTemp.createTemp('bedbug_test_');
  Hive.init(tempDir.path);
  if (!_areAdaptersRegistered) {
    Hive.registerAdapters();
    _areAdaptersRegistered = true;
  }
  await Future.wait([
    Hive.openBox<SignatureHiveModel>('signatures'),
    Hive.openBox<ContentHiveModel>('contents'),
    Hive.openBox<CommentHiveModel>('comments'),
    Hive.openBox<ReactionHiveModel>('reactions'),
    Hive.openBox<KeychainHiveModel>('keychains'),
    Hive.openBox<StorageHiveModel>('storage'),
    Hive.openBox<SettingsHiveModel>('settings'),
    Hive.openBox<Uint8List>(drawingDraftBoxName),
    Hive.openBox<TrustSettingsHiveModel>(trustSettingsBoxName),
    Hive.openBox<int>(seenContentBoxName),
    Hive.openBox<int>(viewedContentBoxName),
    Hive.openBox<ExchangeLogHiveModel>(exchangeLogBoxName),
    Hive.openBox<ErrorLogHiveModel>(errorLogBoxName),
  ]);
  return tempDir;
}

/// Ferme toutes les boxes Hive et supprime le répertoire temporaire créé par
/// [openTestHive].
Future<void> closeTestHive(Directory tempDir) async {
  await Hive.close();
  if (tempDir.existsSync()) {
    tempDir.deleteSync(recursive: true);
  }
}
