import 'dart:math';
import 'dart:typed_data';

import 'package:bedbug/features/content/domain/entities/drawing_content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/object_values/drawing.dart';
import 'package:bedbug/features/content/domain/object_values/drawing_operation.dart';
import 'package:bedbug/features/content/domain/object_values/drawing_point.dart';
import 'package:bedbug/features/content/domain/services/drawing_validation_service.dart';
import 'package:bedbug/features/content/domain/services/flood_fill_service.dart';
import 'package:bedbug/features/content/domain/services/stroke_simplification_service.dart';
import 'package:bedbug/features/content/infrastructure/models/content_hive_model.dart';
import 'package:bedbug/features/content/infrastructure/models/drawing_binary_codec.dart';
import 'package:flutter_test/flutter_test.dart';

/// Retourne un trait au stylo passant par [points], avec les réglages fournis.
DrawingStroke _stroke(
  List<DrawingPoint> points, {
  int layer = 1,
  int colorIndex = 0,
  DrawingBrush brush = DrawingBrush.pen,
  int size = 1,
  int seed = 42,
}) {
  return DrawingStroke(layer: layer, colorIndex: colorIndex, brush: brush, size: size, seed: seed, points: points);
}

/// Retourne un dessin à la palette par défaut, composé de [operations].
Drawing _drawing(List<DrawingOperation> operations) {
  return Drawing(palette: defaultDrawingPalette, operations: operations);
}

/// Retourne une ligne horizontale de [count] points.
List<DrawingPoint> _line(int count) {
  return [for (var index = 0; index < count; index++) DrawingPoint(index % drawingWidth, 10)];
}

void main() {
  const validation = DrawingValidationService();
  const simplification = StrokeSimplificationService();
  const floodFill = FloodFillService();
  const codec = DrawingBinaryCodec();

  final sample = _drawing([
    _stroke(const [DrawingPoint(0, 0), DrawingPoint(1023, 767), DrawingPoint(5, 700)], brush: DrawingBrush.pencil),
    const DrawingFill(layer: 0, colorIndex: 6, point: DrawingPoint(512, 384)),
    _stroke(
      const [DrawingPoint(300, 300)],
      layer: 2,
      colorIndex: 15,
      brush: DrawingBrush.spray,
      size: 3,
      seed: maxDrawingSeed,
    ),
    _stroke(const [DrawingPoint(10, 10), DrawingPoint(9, 8)], brush: DrawingBrush.eraser, size: 0, seed: 0),
  ]);

  group('limites d\'un dessin', () {
    test('accepte un dessin dans les limites, et un dessin vide', () {
      expect(validation.isValid(sample), isTrue);
      expect(validation.isValid(const Drawing.empty()), isTrue);
    });

    test('refuse une palette qui n\'a pas exactement 16 couleurs opaques', () {
      expect(validation.isValid(Drawing(palette: defaultDrawingPalette.sublist(1), operations: const [])), isFalse);
      expect(
        validation.isValid(const Drawing(palette: [...defaultDrawingPalette, 0xFF000000], operations: [])),
        isFalse,
      );
      for (final color in [0x80FF0000, 0x00000000, -1, 0x1FFFFFFFF]) {
        final palette = [...defaultDrawingPalette]..[3] = color;
        expect(
          validation.isValid(Drawing(palette: palette, operations: const [])),
          isFalse,
          reason: '$color',
        );
      }
    });

    test('refuse un calque, une couleur, une taille ou une graine hors limites', () {
      const point = [DrawingPoint(1, 1)];
      for (final stroke in [
        _stroke(point, layer: -1),
        _stroke(point, layer: drawingLayerCount),
        _stroke(point, colorIndex: -1),
        _stroke(point, colorIndex: drawingPaletteSize),
        _stroke(point, size: -1),
        _stroke(point, size: drawingBrushSizeCount),
        _stroke(point, seed: -1),
        _stroke(point, seed: maxDrawingSeed + 1),
      ]) {
        expect(validation.isValid(_drawing([stroke])), isFalse, reason: '$stroke');
      }
      expect(
        validation.isValid(_drawing([const DrawingFill(layer: 3, colorIndex: 0, point: DrawingPoint(1, 1))])),
        isFalse,
      );
    });

    test('refuse un point hors du repère, pour un trait comme pour un remplissage', () {
      for (final point in const [
        DrawingPoint(-1, 0),
        DrawingPoint(0, -1),
        DrawingPoint(drawingWidth, 0),
        DrawingPoint(0, drawingHeight),
      ]) {
        expect(
          validation.isValid(
            _drawing([
              _stroke([const DrawingPoint(5, 5), point]),
            ]),
          ),
          isFalse,
          reason: '$point',
        );
        expect(validation.isValid(_drawing([DrawingFill(layer: 0, colorIndex: 0, point: point)])), isFalse);
      }
    });

    test('refuse un trait vide ou trop long, et un dessin qui a trop de points en tout', () {
      expect(validation.isValid(_drawing([_stroke(const [])])), isFalse);
      expect(validation.isValid(_drawing([_stroke(_line(maxDrawingStrokePoints))])), isTrue);
      expect(validation.isValid(_drawing([_stroke(_line(maxDrawingStrokePoints + 1))])), isFalse);

      final strokeCount = maxDrawingPoints ~/ maxDrawingStrokePoints;
      final full = [for (var index = 0; index < strokeCount; index++) _stroke(_line(maxDrawingStrokePoints))];
      expect(validation.isValid(_drawing(full)), isTrue);
      expect(validation.isValid(_drawing([...full, _stroke(_line(1))])), isFalse);
    });

    test('refuse trop d\'opérations, ou trop de remplissages', () {
      final dots = [
        for (var index = 0; index < maxDrawingOperations; index++) _stroke(const [DrawingPoint(1, 1)]),
      ];
      expect(validation.isValid(_drawing(dots)), isTrue);
      expect(
        validation.isValid(
          _drawing([
            ...dots,
            _stroke(const [DrawingPoint(1, 1)]),
          ]),
        ),
        isFalse,
      );

      const fill = DrawingFill(layer: 0, colorIndex: 0, point: DrawingPoint(1, 1));
      expect(validation.isValid(_drawing(List.filled(maxDrawingFills, fill))), isTrue);
      expect(validation.isValid(_drawing(List.filled(maxDrawingFills + 1, fill))), isFalse);
    });
  });

  group('simplification des traits', () {
    test('une ligne droite ne garde que ses extrémités', () {
      final points = [for (var x = 0; x <= 100; x++) DrawingPoint(x, 2 * x)];
      expect(simplification.simplify(points), const [DrawingPoint(0, 0), DrawingPoint(100, 200)]);
    });

    test('garde les angles, et fusionne les points répétés', () {
      final points = [
        for (var x = 0; x <= 50; x++) DrawingPoint(x, 0),
        const DrawingPoint(50, 0),
        for (var y = 1; y <= 50; y++) DrawingPoint(50, y),
      ];
      expect(simplification.simplify(points), const [DrawingPoint(0, 0), DrawingPoint(50, 0), DrawingPoint(50, 50)]);
    });

    test('un point seul ou répété reste un point', () {
      expect(simplification.simplify(const [DrawingPoint(3, 4)]), const [DrawingPoint(3, 4)]);
      expect(simplification.simplify(const [DrawingPoint(3, 4), DrawingPoint(3, 4)]), const [DrawingPoint(3, 4)]);
      expect(simplification.simplify(const []), isEmpty);
    });
  });

  group('pot de peinture', () {
    const size = 20;

    /// Image blanche de [size]×[size] pixels, avec un carré noir de bord 1 de (5, 5) à (14, 14).
    Uint8List framedImage() {
      final rgba = Uint8List(size * size * 4)..fillRange(0, size * size * 4, 255);
      for (var y = 5; y <= 14; y++) {
        for (var x = 5; x <= 14; x++) {
          if (x == 5 || x == 14 || y == 5 || y == 14) {
            final offset = (y * size + x) * 4;
            rgba.setRange(offset, offset + 3, const [0, 0, 0]);
          }
        }
      }
      return rgba;
    }

    test('remplit l\'intérieur d\'un contour sans en sortir, en débordant d\'un pixel sur le bord', () {
      final mask = floodFill.fillMask(framedImage(), size, size, 10, 10);
      expect(mask[10 * size + 10], 255);
      // Le bord du carré est recouvert (agrandissement d'un pixel)…
      expect(mask[5 * size + 10], 255);
      // … mais rien au-delà.
      expect(mask[4 * size + 10], 0);
      expect(mask[0], 0);
      expect(mask.where((value) => value == 255).length, 10 * 10 - 4);
    });

    test('remplit l\'extérieur sans entrer dans le contour', () {
      final mask = floodFill.fillMask(framedImage(), size, size, 0, 0);
      expect(mask[0], 255);
      expect(mask[size * size - 1], 255);
      expect(mask[10 * size + 10], 0);
    });

    test('un point hors de l\'image, ou une image de taille incohérente, ne remplit rien', () {
      for (final (x, y) in const [(-1, 0), (0, -1), (size, 0), (0, size)]) {
        expect(floodFill.fillMask(framedImage(), size, size, x, y).every((value) => value == 0), isTrue);
      }
      expect(floodFill.fillMask(Uint8List(10), size, size, 1, 1).every((value) => value == 0), isTrue);
      expect(floodFill.fillMask(framedImage(), 0, 0, 0, 0), isEmpty);
      expect(floodFill.fillMask(framedImage(), -3, size, 0, 0), isEmpty);
    });
  });

  group('encodage', () {
    test('relit à l\'identique un dessin encodé, et reste compact', () {
      final bytes = codec.encode(sample);
      expect(codec.decode(bytes), sample);

      // Un trait de 1000 points rapprochés tient en un peu plus de 2 octets par point.
      final dense = _drawing([
        _stroke([for (var index = 0; index < 1000; index++) DrawingPoint(500 + (index % 40), 300 + (index % 25))]),
      ]);
      expect(codec.encode(dense).length, lessThan(2200));
    });

    test('refuse une signature inconnue, un flux tronqué à n\'importe quel endroit, ou des octets en trop', () {
      final bytes = codec.encode(sample);
      expect(() => codec.decode(Uint8List.fromList([0, ...bytes.sublist(1)])), throwsFormatException);
      for (var length = 0; length < bytes.length; length++) {
        expect(() => codec.decode(bytes.sublist(0, length)), throwsFormatException, reason: 'longueur $length');
      }
      expect(() => codec.decode(Uint8List.fromList([...bytes, 0])), throwsFormatException);
    });

    test('refuse un nombre d\'opérations ou de points annoncé hors limites, avant de les lire', () {
      final header = [
        0x42,
        0x42,
        0x44,
        0x01,
        drawingPaletteSize,
        for (var index = 0; index < drawingPaletteSize * 4; index++) 0xFF,
      ];
      // 501 opérations annoncées (varint 0xF5 0x03), sans aucune derrière.
      expect(() => codec.decode(Uint8List.fromList([...header, 0xF5, 0x03])), throwsFormatException);
      // Un trait qui annonce 1001 points (varint 0xE9 0x07).
      final stroke = [_strokeTagByte, 1, 0, 0, 1, 0, 0, 0, 0, 0xE9, 0x07];
      expect(() => codec.decode(Uint8List.fromList([...header, 1, ...stroke])), throwsFormatException);
      // Un entier sans fin (le bit de suite toujours levé).
      expect(
        () => codec.decode(Uint8List.fromList([...header, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01])),
        throwsFormatException,
      );
    });

    test('refuse un pinceau ou une opération inconnus', () {
      final header = [
        0x42,
        0x42,
        0x44,
        0x01,
        drawingPaletteSize,
        for (var index = 0; index < drawingPaletteSize * 4; index++) 0xFF,
      ];
      expect(() => codec.decode(Uint8List.fromList([...header, 1, 7, 0, 0])), throwsFormatException);
      expect(
        () => codec.decode(Uint8List.fromList([...header, 1, _strokeTagByte, 0, 0, 99, 0, 0, 0, 0, 0, 0])),
        throwsFormatException,
      );
    });

    test('des octets au hasard ne font jamais rien d\'autre qu\'un refus propre', () {
      final random = Random(1);
      final bytes = codec.encode(sample);
      for (var round = 0; round < 2000; round++) {
        final mutated = Uint8List.fromList(bytes);
        // Quelques octets modifiés au hasard dans un vrai dessin, ou un flux entièrement aléatoire.
        if (round.isEven) {
          for (var change = 0; change < 3; change++) {
            mutated[random.nextInt(mutated.length)] = random.nextInt(256);
          }
        }
        final input = round.isEven
            ? mutated
            : Uint8List.fromList([for (var index = 0; index < random.nextInt(200); index++) random.nextInt(256)]);
        try {
          final decoded = codec.decode(input);
          // Un flux qui se lit n'est pas forcément dans les limites : c'est le rôle de la vérification.
          validation.isValid(decoded);
        } on FormatException {
          // Refus attendu.
        }
      }
    });
  });

  test('un contenu dessiné se stocke et se relit à l\'identique', () {
    final now = DateTime.fromMillisecondsSinceEpoch(1000);
    final content = DrawingContent(
      id: 'd',
      createdAt: now,
      updatedAt: now,
      authorId: 'author',
      origin: ContentOrigin.owned,
      broadcastScore: 1,
      survivalScore: 1,
      displayScore: 1,
      bounce: 0,
      senderId: 'local',
      sizeInBytes: 10,
      flair: 'dessin',
      drawing: sample,
      title: 'Mon dessin',
    );
    final reread = ContentHiveModel.fromEntity(content).toEntity() as DrawingContent;
    expect(reread.drawing, sample);
    expect(reread.title, 'Mon dessin');
  });
}

/// Marqueur d'un trait dans le flux encodé (voir `DrawingBinaryCodec`).
const int _strokeTagByte = 0;
