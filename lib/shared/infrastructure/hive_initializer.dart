import 'package:bedbug/features/content/infrastructure/models/comment_hive_model.dart';
import 'package:bedbug/features/content/infrastructure/models/content_hive_model.dart';
import 'package:bedbug/features/content/infrastructure/models/storage_hive_model.dart';
import 'package:bedbug/features/content/infrastructure/models/sub_hive_model.dart';
import 'package:bedbug/features/discovery/infrastructure/models/keychain_hive_model.dart';
import 'package:bedbug/features/settings/infrastructure/models/settings_hive_model.dart';
import 'package:bedbug/features/user/infrastructure/models/user_hive_model.dart';
import 'package:bedbug/hive_registrar.g.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Initialise Hive, enregistre les adapters et ouvre toutes les boxes.
///
/// À appeler une seule fois au démarrage de l'application, avant tout
/// accès aux repositories.
Future<void> initHive() async {
  await Hive.initFlutter();
  Hive.registerAdapters();
  await Future.wait([
    Hive.openBox<UserHiveModel>('users'),
    Hive.openBox<ContentHiveModel>('contents'),
    Hive.openBox<CommentHiveModel>('comments'),
    Hive.openBox<SubHiveModel>('subs'),
    Hive.openBox<KeychainHiveModel>('keychains'),
    Hive.openBox<StorageHiveModel>('storage'),
    Hive.openBox<SettingsHiveModel>('settings'),
  ]);
}
