import 'dart:io';
import 'dart:typed_data';

import 'package:bedbug/features/content/infrastructure/datasources/hive_drawing_draft_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_seen_content_repository.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_trust_settings_repository.dart';
import 'package:bedbug/features/content/infrastructure/models/comment_hive_model.dart';
import 'package:bedbug/features/content/infrastructure/models/content_hive_model.dart';
import 'package:bedbug/features/content/infrastructure/models/reaction_hive_model.dart';
import 'package:bedbug/features/content/infrastructure/models/storage_hive_model.dart';
import 'package:bedbug/features/content/infrastructure/models/trust_settings_hive_model.dart';
import 'package:bedbug/features/discovery/infrastructure/models/keychain_hive_model.dart';
import 'package:bedbug/features/settings/infrastructure/models/settings_hive_model.dart';
import 'package:bedbug/features/signature/infrastructure/models/signature_hive_model.dart';
import 'package:bedbug/hive_registrar.g.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Ancien dossier des fichiers images, du temps où les images étaient transférées entre pairs.
const String _legacyContentImagesFolder = 'content_images';

/// Initialise Hive, enregistre les adapters et ouvre toutes les boxes.
///
/// À appeler une seule fois au démarrage de l'application, avant tout
/// accès aux repositories.
Future<void> initHive() async {
  await Hive.initFlutter();
  Hive.registerAdapters();
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
  ]);
  await _purgeLegacyImageContents();
}

/// Supprime les anciens contenus image et leurs fichiers.
///
/// Les images ne sont plus transférées de pair à pair : elles sont
/// hébergées sur des sites reconnus et référencées par leur URL. Les
/// contenus image d'avant, stockés en fichiers locaux, ne peuvent plus être
/// relus et sont supprimés une fois pour toutes.
Future<void> _purgeLegacyImageContents() async {
  final contentsBox = Hive.box<ContentHiveModel>('contents');
  final legacyKeys = [
    for (final key in contentsBox.keys)
      if (contentsBox.get(key)?.isLegacyImageContent ?? false) key,
  ];
  await contentsBox.deleteAll(legacyKeys);

  final documentsDirectory = await getApplicationDocumentsDirectory();
  final legacyImagesDirectory = Directory('${documentsDirectory.path}/$_legacyContentImagesFolder');
  if (legacyImagesDirectory.existsSync()) {
    await legacyImagesDirectory.delete(recursive: true);
  }
}
