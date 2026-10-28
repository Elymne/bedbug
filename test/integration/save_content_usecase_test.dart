import 'dart:io';

import 'package:bedbug/features/content/domain/entities/drawing_content.dart';
import 'package:bedbug/features/content/domain/entities/link_content.dart';
import 'package:bedbug/features/content/domain/entities/media_content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/object_values/content_media.dart';
import 'package:bedbug/features/content/domain/object_values/drawing.dart';
import 'package:bedbug/features/content/domain/object_values/drawing_operation.dart';
import 'package:bedbug/features/content/domain/object_values/drawing_point.dart';
import 'package:bedbug/features/content/domain/usecases/save_content_usecase.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_content_repository.dart';
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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      _pathProviderChannel,
      null,
    );
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
      flair: 'test',
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

    final saved = (await repository.getAll()).firstWhere((content) => content.id == 'a');
    expect(saved.sizeInBytes, 5);
  });

  test(
    'ignore le sizeInBytes fourni par l\'appelant pour un LinkContent et le recalcule depuis ses champs texte',
    () async {
      final saveUsecase = container.read(saveContentUsecaseProvider);
      final repository = container.read(contentRepositoryProvider);

      final now = DateTime.now();
      final content = LinkContent(
        id: 'a',
        createdAt: now,
        updatedAt: now,
        authorId: 'author',
        senderId: 'sender',
        flair: 'test',
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

      final saved = (await repository.getAll()).firstWhere((content) => content.id == 'a');
      expect(saved.sizeInBytes, 5);
    },
  );

  test(
    "ignore le sizeInBytes fourni par l'appelant pour un MediaContent et ne compte que ses textes et ses adresses",
    () async {
      final saveUsecase = container.read(saveContentUsecaseProvider);
      final repository = container.read(contentRepositoryProvider);

      final now = DateTime.now();
      final content = MediaContent(
        id: 'a',
        createdAt: now,
        updatedAt: now,
        authorId: 'author',
        senderId: 'sender',
        flair: 'test',
        origin: ContentOrigin.owned,
        broadcastScore: 1,
        survivalScore: 1,
        displayScore: 1,
        bounce: 0,
        sizeInBytes: 999999,
        media: const [
          ContentMedia(url: 'https://a.io/1.png', kind: MediaKind.image),
          ContentMedia(url: 'https://a.io/2.mp4', kind: MediaKind.video),
        ],
        title: 'Titre',
        body: 'é',
      );

      await saveUsecase(SaveContentParams(content: content));

      final saved = (await repository.getAll()).firstWhere((content) => content.id == 'a') as MediaContent;
      // « Titre » (5) + « é » (2 octets en UTF-8) + deux adresses de 18 caractères.
      expect(saved.sizeInBytes, 5 + 2 + 18 + 18);
      expect(saved.media.map((media) => media.kind), [MediaKind.image, MediaKind.video]);
    },
  );

  /// Retourne un contenu dessiné composé de [drawing].
  DrawingContent drawingContent(Drawing drawing) {
    final now = DateTime.now();
    return DrawingContent(
      id: 'd',
      createdAt: now,
      updatedAt: now,
      authorId: 'author',
      senderId: 'sender',
      flair: 'test',
      origin: ContentOrigin.owned,
      broadcastScore: 1,
      survivalScore: 1,
      displayScore: 1,
      bounce: 0,
      sizeInBytes: 0,
      drawing: drawing,
      title: 'Titre',
    );
  }

  test('enregistre un dessin dans les limites, et compte son titre et une borne de ses opérations', () async {
    final saveUsecase = container.read(saveContentUsecaseProvider);
    const stroke = DrawingStroke(
      layer: 1,
      colorIndex: 0,
      brush: DrawingBrush.pen,
      size: 1,
      seed: 1,
      points: [DrawingPoint(1, 1), DrawingPoint(2, 2)],
    );
    const drawing = Drawing(palette: defaultDrawingPalette, operations: [stroke]);

    final result = await saveUsecase(SaveContentParams(content: drawingContent(drawing)));

    // « Titre » (5) + 16 couleurs × 4 + 1 opération × 12 + 2 points × 4.
    expect(result.right!.sizeInBytes, 5 + 64 + 12 + 8);
    final saved = (await container.read(contentRepositoryProvider).getAll()).single as DrawingContent;
    expect(saved.drawing, drawing);
  });

  test("refuse d'enregistrer un dessin hors limites", () async {
    final saveUsecase = container.read(saveContentUsecaseProvider);
    final tooManyColors = const Drawing(palette: [...defaultDrawingPalette, 0xFF123456], operations: []);

    final result = await saveUsecase(SaveContentParams(content: drawingContent(tooManyColors)));

    expect(result.left, SaveContentFailure.invalidContent);
    expect(await container.read(contentRepositoryProvider).getAll(), isEmpty);
  });
}
