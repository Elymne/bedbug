import 'dart:io';

import 'package:bedbug/features/content/infrastructure/models/comment_hive_model.dart';
import 'package:bedbug/features/content/infrastructure/models/content_hive_model.dart';
import 'package:bedbug/features/content/infrastructure/models/storage_hive_model.dart';
import 'package:bedbug/features/content/infrastructure/models/sub_hive_model.dart';
import 'package:bedbug/features/discovery/infrastructure/models/keychain_hive_model.dart';
import 'package:bedbug/features/settings/infrastructure/models/settings_hive_model.dart';
import 'package:bedbug/features/user/infrastructure/models/user_hive_model.dart';
import 'package:bedbug/hive_registrar.g.dart';
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
    Hive.openBox<UserHiveModel>('users'),
    Hive.openBox<ContentHiveModel>('contents'),
    Hive.openBox<CommentHiveModel>('comments'),
    Hive.openBox<SubHiveModel>('subs'),
    Hive.openBox<KeychainHiveModel>('keychains'),
    Hive.openBox<StorageHiveModel>('storage'),
    Hive.openBox<SettingsHiveModel>('settings'),
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
