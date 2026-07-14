import 'dart:io';

import 'package:bedbug/features/content/domain/entities/image_content.dart';
import 'package:bedbug/features/content/domain/entities/link_content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/usecases/save_content_usecase.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
import 'package:bedbug/shared/config/content_image_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/hive_test_helper.dart';

/// Canal utilisé par `path_provider` pour résoudre le dossier de documents.
///
/// Mocké ici pour rediriger vers le répertoire temporaire de test, sans
/// dépendre d'une vraie plateforme, comme le fait déjà `openTestHive` pour Hive.
const MethodChannel _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await openTestHive();
    container = ProviderContainer();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_pathProviderChannel, (
      call,
    ) async {
      if (call.method == 'getApplicationDocumentsDirectory') return tempDir.path;
      return null;
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_pathProviderChannel, null);
    container.dispose();
    await closeTestHive(tempDir);
  });

  test('ignore le sizeInBytes fourni par l\'appelant pour un TextContent et le recalcule depuis title/body', () async {
    final saveUsecase = container.read(saveContentUsecaseProvider);
    final repository = container.read(contentRepositoryProvider);

    final now = DateTime.now();
    final content = TextContent(
      id: 'a',
      createdAt: now,
      updatedAt: now,
      authorId: 'author',
      senderId: 'sender',
      origin: ContentOrigin.owned,
      broadcastScore: 1,
      survivalScore: 1,
      displayScore: 1,
      bounce: 0,
      sizeInBytes: 999999,
      title: 'ab',
      body: 'cde',
    );

    await saveUsecase(SaveContentParams(content: content));

    final saved = (await repository.getUnique('a'))!;
    expect(saved.sizeInBytes, 5);
  });

  test('ignore le sizeInBytes fourni par l\'appelant pour un LinkContent et le recalcule depuis ses champs texte', () async {
    final saveUsecase = container.read(saveContentUsecaseProvider);
    final repository = container.read(contentRepositoryProvider);

    final now = DateTime.now();
    final content = LinkContent(
      id: 'a',
      createdAt: now,
      updatedAt: now,
      authorId: 'author',
      senderId: 'sender',
      origin: ContentOrigin.owned,
      broadcastScore: 1,
      survivalScore: 1,
      displayScore: 1,
      bounce: 0,
      sizeInBytes: 999999,
      title: 'ab',
      url: 'cde',
    );

    await saveUsecase(SaveContentParams(content: content));

    final saved = (await repository.getUnique('a'))!;
    expect(saved.sizeInBytes, 5);
  });

  test('ignore le sizeInBytes fourni par l\'appelant pour un ImageContent et lit la vraie taille du fichier sur disque', () async {
    final saveUsecase = container.read(saveContentUsecaseProvider);
    final repository = container.read(contentRepositoryProvider);

    final imagesDir = Directory('${tempDir.path}/$contentImagesFolder');
    await imagesDir.create(recursive: true);
    final file = File('${imagesDir.path}/photo.jpg');
    await file.writeAsBytes(List.filled(1234, 0));

    final now = DateTime.now();
    final content = ImageContent(
      id: 'a',
      createdAt: now,
      updatedAt: now,
      authorId: 'author',
      senderId: 'sender',
      origin: ContentOrigin.owned,
      broadcastScore: 1,
      survivalScore: 1,
      displayScore: 1,
      bounce: 0,
      sizeInBytes: 1,
      fileName: 'photo.jpg',
      imageWidth: 100,
      imageHeight: 100,
      title: 'Titre',
    );

    await saveUsecase(SaveContentParams(content: content));

    final saved = (await repository.getUnique('a'))!;
    expect(saved.sizeInBytes, 1234);
  });

  test('retourne un poids de 0 pour un ImageContent dont le fichier est introuvable sur disque', () async {
    final saveUsecase = container.read(saveContentUsecaseProvider);
    final repository = container.read(contentRepositoryProvider);

    final now = DateTime.now();
    final content = ImageContent(
      id: 'a',
      createdAt: now,
      updatedAt: now,
      authorId: 'author',
      senderId: 'sender',
      origin: ContentOrigin.owned,
      broadcastScore: 1,
      survivalScore: 1,
      displayScore: 1,
      bounce: 0,
      sizeInBytes: 999999,
      fileName: 'missing.jpg',
      imageWidth: 100,
      imageHeight: 100,
      title: 'Titre',
    );

    await saveUsecase(SaveContentParams(content: content));

    final saved = (await repository.getUnique('a'))!;
    expect(saved.sizeInBytes, 0);
  });
}
