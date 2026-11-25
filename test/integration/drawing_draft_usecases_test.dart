import 'dart:typed_data';

import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/infra/resources/content/drawing/drawing.config.dart';
import 'package:bedbug/infra/resources/content/drawing/drawing.value_object.dart';
import 'package:bedbug/infra/resources/drift.config.dart';
import 'package:bedbug/infra/resources/drift.database.dart';
import 'package:bedbug/logic/usecases/content/get_drawing_draft/get_drawing_draft.failure.dart';
import 'package:bedbug/logic/usecases/content/get_drawing_draft/get_drawing_draft.usecase.dart';
import 'package:bedbug/logic/usecases/content/save_drawing_draft/save_drawing_draft.params.dart';
import 'package:bedbug/logic/usecases/content/save_drawing_draft/save_drawing_draft.usecase.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/drift_test_helper.dart';

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
  late ProviderContainer container;

  setUp(() {
    container = createTestContainer();
  });

  tearDown(() {
    container.dispose();
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
    final database = container.read(appDatabaseProvider);
    await database
        .into(database.drawingDrafts)
        .insert(DrawingDraftsCompanion.insert(id: const Value(singleRowId), data: Uint8List.fromList([1, 2, 3])));

    final result = await container.read(getDrawingDraftUsecaseProvider)(const NoParams());

    expect(result.left, GetDrawingDraftFailure.invalidData);
  });
}
