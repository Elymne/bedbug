import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bedbug/application/providers/drawing_rasterizer_provider.dart';
import 'package:bedbug/features/content/domain/object_values/drawing.dart';
import 'package:bedbug/features/content/domain/object_values/drawing_operation.dart';
import 'package:bedbug/features/content/domain/object_values/drawing_point.dart';
import 'package:bedbug/features/content/domain/services/flood_fill_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contour carré fermé de (300, 200) à (700, 600), au stylo épais.
const DrawingStroke _square = DrawingStroke(
  layer: 1,
  colorIndex: 0,
  brush: DrawingBrush.pen,
  size: 2,
  seed: 1,
  points: [
    DrawingPoint(300, 200),
    DrawingPoint(700, 200),
    DrawingPoint(700, 600),
    DrawingPoint(300, 600),
    DrawingPoint(300, 200),
  ],
);

void main() {
  const rasterizer = DrawingRasterizer(FloodFillService());

  /// Calcule l'image de [operations], et retourne ses pixels RGBA.
  Future<Uint8List> pixelsOf(WidgetTester tester, List<DrawingOperation> operations) async {
    final bytes = await tester.runAsync(() async {
      final image = await rasterizer.render(Drawing(palette: defaultDrawingPalette, operations: operations));
      expect(image.width, drawingRasterWidth);
      expect(image.height, drawingRasterHeight);
      return image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
    });
    return bytes!.buffer.asUint8List();
  }

  /// Couleur RGB du pixel de l'image correspondant au point (x, y) du repère.
  List<int> colorAt(Uint8List pixels, int x, int y) {
    final offset = ((y ~/ 2) * drawingRasterWidth + (x ~/ 2)) * 4;
    return pixels.sublist(offset, offset + 3);
  }

  /// Composantes RGB de la couleur en position [index] de la palette par défaut.
  List<int> paletteRgb(int index) {
    final color = defaultDrawingPalette[index];
    return [(color >> 16) & 0xFF, (color >> 8) & 0xFF, color & 0xFF];
  }

  const white = [255, 255, 255];

  testWidgets('un dessin vide est un fond blanc', (tester) async {
    final pixels = await pixelsOf(tester, const []);
    expect(colorAt(pixels, 0, 0), white);
    expect(colorAt(pixels, 512, 384), white);
  });

  testWidgets('un remplissage reste à l\'intérieur du contour, même posé sur un autre calque', (tester) async {
    final pixels = await pixelsOf(tester, const [
      _square,
      DrawingFill(layer: 0, colorIndex: 6, point: DrawingPoint(500, 400)),
    ]);
    expect(colorAt(pixels, 500, 400), paletteRgb(6));
    expect(colorAt(pixels, 320, 220), paletteRgb(6));
    expect(colorAt(pixels, 100, 100), white);
    expect(colorAt(pixels, 900, 700), white);
    // Le contour, sur le calque du dessus, reste visible par-dessus le remplissage.
    expect(colorAt(pixels, 500, 200), paletteRgb(0));
  });

  testWidgets('la gomme n\'efface que son calque', (tester) async {
    const eraser = DrawingStroke(
      layer: 1,
      colorIndex: 0,
      brush: DrawingBrush.eraser,
      size: 3,
      seed: 1,
      points: [DrawingPoint(500, 100), DrawingPoint(500, 700)],
    );
    final pixels = await pixelsOf(tester, const [
      DrawingFill(layer: 0, colorIndex: 10, point: DrawingPoint(10, 10)),
      _square,
      eraser,
    ]);
    // Le contour est effacé là où la gomme est passée, mais le fond rempli du calque 0 reste.
    expect(colorAt(pixels, 500, 200), paletteRgb(10));
    expect(colorAt(pixels, 300, 400), paletteRgb(0));
  });

  testWidgets('le même dessin donne exactement la même image, bombe et crayon compris', (tester) async {
    const operations = [
      DrawingStroke(
        layer: 1,
        colorIndex: 4,
        brush: DrawingBrush.spray,
        size: 3,
        seed: 1234,
        points: [DrawingPoint(200, 200), DrawingPoint(400, 300)],
      ),
      DrawingStroke(
        layer: 2,
        colorIndex: 0,
        brush: DrawingBrush.pencil,
        size: 2,
        seed: 99,
        points: [DrawingPoint(600, 600), DrawingPoint(900, 400)],
      ),
    ];
    final first = await pixelsOf(tester, operations);
    final second = await pixelsOf(tester, operations);
    expect(first, second);
    // Et la bombe a bien laissé des points de couleur.
    expect(first.any((value) => value != 255), isTrue);
  });
}
