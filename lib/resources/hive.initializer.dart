import 'dart:io';
import 'dart:typed_data';

import 'package:bedbug/hive_registrar.g.dart';
import 'package:bedbug/resources/content/comment/comment.model.hive.dart';
import 'package:bedbug/resources/content/content/content.model.hive.dart';
import 'package:bedbug/resources/content/drawing/drawing.config.dart';
import 'package:bedbug/resources/content/reaction/reaction.model.hive.dart';
import 'package:bedbug/resources/content/seen_content/seen_content.config.dart';
import 'package:bedbug/resources/content/storage/storage.model.hive.dart';
import 'package:bedbug/resources/content/trust_settings/trust_settings.config.dart';
import 'package:bedbug/resources/content/trust_settings/trust_settings.model.hive.dart';
import 'package:bedbug/resources/content/viewed_content/viewed_content.config.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.config.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.model.hive.dart';
import 'package:bedbug/resources/exchange/exchange_log/exchange_log.config.dart';
import 'package:bedbug/resources/exchange/exchange_log/exchange_log.model.hive.dart';
import 'package:bedbug/resources/exchange/keychain/keychain.model.hive.dart';
import 'package:bedbug/resources/settings/settings/settings.model.hive.dart';
import 'package:bedbug/resources/signature/signature/signature.model.hive.dart';
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
    Hive.openBox<int>(viewedContentBoxName),
    Hive.openBox<ExchangeLogHiveModel>(exchangeLogBoxName),
    Hive.openBox<ErrorLogHiveModel>(errorLogBoxName),
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
