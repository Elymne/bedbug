import 'dart:io';
import 'dart:typed_data';

import 'package:bedbug/features/content/domain/object_values/drawing.dart';
import 'package:bedbug/features/content/domain/object_values/drawing_operation.dart';
import 'package:bedbug/features/content/domain/object_values/drawing_point.dart';
import 'package:bedbug/features/content/domain/usecases/get_drawing_draft_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/save_drawing_draft_usecase.dart';
import 'package:bedbug/features/content/infrastructure/datasources/hive_drawing_draft_repository.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../helpers/hive_test_helper.dart';

/// Dessin en cours : un trait sur une grande surface en portrait.
const Drawing _draft = Drawing(
  size: DrawingSize.large,
  orientation: DrawingOrientation.portrait,
  palette: defaultDrawingPalette,
  operations: [
    DrawingStroke(
      layer: 1,
      colorIndex: 4,
      brush: DrawingBrush.marker,
      size: 2,
      seed: 7,
      points: [DrawingPoint(10, 10), DrawingPoint(1100, 1500)],
    ),
  ],
);

void main() {
  late Directory tempDir;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await openTestHive();
    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    await closeTestHive(tempDir);
  });

  test('il n\'y a pas de brouillon tant que rien n\'a été dessiné', () async {
    final result = await container.read(getDrawingDraftUsecaseProvider)(const NoParams());

    expect(result.isSuccess, isTrue);
    expect(result.right, isNull);
  });

  test('un brouillon enregistré se relit à l\'identique, surface comprise, puis s\'efface', () async {
    final save = container.read(saveDrawingDraftUsecaseProvider);
    final get = container.read(getDrawingDraftUsecaseProvider);

    expect((await save(const SaveDrawingDraftParams(drawing: _draft))).isSuccess, isTrue);
    expect((await get(const NoParams())).right, _draft);

    expect((await save(const SaveDrawingDraftParams(drawing: null))).isSuccess, isTrue);
    expect((await get(const NoParams())).right, isNull);
  });

  test('un brouillon illisible est signalé, sans bloquer', () async {
    await Hive.box<Uint8List>(drawingDraftBoxName).put('drawing_draft', Uint8List.fromList([1, 2, 3]));

    final result = await container.read(getDrawingDraftUsecaseProvider)(const NoParams());

    expect(result.left, DrawingDraftFailure.invalidData);
  });
}
